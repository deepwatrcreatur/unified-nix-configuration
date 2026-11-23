{ config, lib, pkgs, ... }:
# Manual failover: `standby` hands the router role to elitedesk without a
# redeploy. Activate with
#   sudo /run/current-system/specialisation/standby/bin/switch-to-configuration test
# and return with
#   sudo /run/current-system/bin/switch-to-configuration test
# `test` never changes the boot entry, so the boot guard below decides what a
# reboot comes back as. Procedure: nix-clan-homelab docs/router-failover.md.
let
  # WHY: free LAN address for the demoted router; 10.10.10.1 moves to
  # elitedesk, which also keeps its own 10.10.10.4.
  standbyLanAddress = "10.10.10.2";
  gateway = "10.10.10.1";
  # WHY: role.nix forces these with mkForce (priority 50); the specialisation
  # must win over it.
  override = lib.mkOverride 40;

  lanDevice = "enp6s16";
  stateDir = "/var/lib/router-failover";
  # INVARIANT: present from standby activation until a deliberate return to
  # primary (switch or test), so a reset of the demoted router cannot bring
  # it back as a second gateway (rehearsal 1, nch-sny.36.2).
  demotedMarker = "${stateDir}/demoted";
  overridesList = "/run/router-failover/overrides";

  bootGuard = pkgs.writeShellScript "router-failover-boot-guard" ''
    set -u
    PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.iproute2 pkgs.iputils ]}
    standby=/run/booted-system/specialisation/standby
    reason=""
    if [ -e ${demotedMarker} ]; then
      reason="${demotedMarker} exists"
    elif ip link show ${lanDevice} >/dev/null 2>&1; then
      ip link set ${lanDevice} up
      for _ in $(seq 1 20); do
        [ "$(cat /sys/class/net/${lanDevice}/carrier 2>/dev/null)" = 1 ] && break
        sleep 0.25
      done
      # GOTCHA: arping -D exits 1 only when another host answers; 2 means it
      # could not probe, which must not demote a healthy primary.
      rc=0
      arping -D -q -c 2 -w 3 -I ${lanDevice} ${gateway} || rc=$?
      if [ "$rc" -eq 1 ]; then
        reason="another host answers for ${gateway}"
      fi
    fi
    [ -n "$reason" ] || exit 0

    echo "router-failover: booting demoted: $reason" >&2
    install -d -m 0755 ${stateDir} /run/systemd/network /run/router-failover
    touch ${demotedMarker}
    : > ${overridesList}
    # WHY: networkd prefers /run over /etc for files of the same name, so the
    # standby specialisation's networks win before networkd first starts.
    for f in "$standby"/etc/systemd/network/*; do
      name="$(basename "$f")"
      cp -L "$f" "/run/systemd/network/$name"
      echo "$name" >> ${overridesList}
    done
  '';

  # Single-active LAN services that must not start on a demoted boot.
  gatedUnits = [
    { name = "kea-dhcp4-server"; on = config.services.kea.dhcp4.enable; }
    { name = "kea-dhcp-ddns-server"; on = config.services.kea.dhcp-ddns.enable; }
    { name = "miniupnpd"; on = config.services.miniupnpd.enable; }
    { name = "inadyn"; on = config.services.inadyn.enable; }
    { name = "avahi-daemon"; on = config.services.avahi.enable; }
  ];
in
{
  systemd.services = lib.mkMerge (
    [
      {
        router-failover-boot-guard = {
          description = "Keep a demoted router off the WAN and ${gateway} after a reboot";
          unitConfig.DefaultDependencies = false;
          wants = [ "sys-subsystem-net-devices-${lanDevice}.device" ];
          after = [
            "local-fs.target"
            "sys-subsystem-net-devices-${lanDevice}.device"
          ];
          before = [
            "systemd-networkd.service"
            "network-pre.target"
            "shutdown.target"
          ];
          conflicts = [ "shutdown.target" ];
          wantedBy = [
            "systemd-networkd.service"
            "multi-user.target"
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = bootGuard;
          };
        };

        # WHY: a guarded boot only fixed networking; activate the full standby
        # specialisation once boot settles, outside the boot transaction.
        router-failover-resume-standby = {
          description = "Finish a demoted boot in the standby specialisation";
          wantedBy = [ "multi-user.target" ];
          after = [ "multi-user.target" ];
          unitConfig.ConditionPathExists = demotedMarker;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${config.systemd.package}/bin/systemd-run --no-block --on-active=5 --unit=router-failover-activate-standby /run/current-system/specialisation/standby/bin/switch-to-configuration test";
          };
        };
      }
    ]
    ++ map (
      u: lib.mkIf u.on { ${u.name}.unitConfig.ConditionPathExists = "!${demotedMarker}"; }
    ) gatedUnits
  );

  # GOTCHA: boot runs activation without NIXOS_ACTION; only a deliberate
  # switch or test to primary clears the marker and the /run overrides.
  system.activationScripts.routerFailoverRole = ''
    case "''${NIXOS_ACTION:-}" in
      switch|test)
        rm -f ${demotedMarker}
        if [ -f ${overridesList} ]; then
          while read -r name; do
            rm -f "/run/systemd/network/$name"
          done < ${overridesList}
          rm -f ${overridesList}
          ${config.systemd.package}/bin/networkctl reload || true
        fi
        ;;
    esac
  '';

  specialisation.standby.configuration = {
    system.nixos.tags = [ "standby" ];

    system.activationScripts.routerFailoverRole = lib.mkForce ''
      install -d -m 0755 ${stateDir}
      touch ${demotedMarker}
    '';
    systemd.services.router-failover-resume-standby.enable = lib.mkForce false;

    # INVARIANT: the modem has one lease; the WAN must be down before
    # elitedesk brings its WAN up with this router's MAC and DUID.
    systemd.network.networks."10-router-wan-primary".linkConfig.ActivationPolicy = override "always-down";

    services.router-networking.routedInterfaces.lan.ipv4Address = override "${standbyLanAddress}/16";
    # GOTCHA: networkd applies the first matching file, and role.nix keeps the
    # LAN's L3 config on the parent file, not on 20-router-lan; override there.
    systemd.network.networks."08-router-parent-enp6s16" = {
      address = override [ "${standbyLanAddress}/16" ];
      gateway = [ gateway ];
      networkConfig = {
        # GOTCHA: stopping sd-radv sends a final RA with lifetime 0, so
        # clients drop this router as their IPv6 default route at once.
        IPv6SendRA = override false;
        DHCPPrefixDelegation = override false;
      };
    };

    # GOTCHA: disabling Kea removes its group, but the agenix TSIG secret
    # (role.nix) still sets group = "kea"; keep the group so activation works.
    users.groups.kea = { };

    # Single-active LAN services move to elitedesk.
    services.router-kea.enable = override false;
    services.router-ddns.enable = override false;
    services.router-upnp.enable = override false;
    services.router-mdns.enable = override false;

    # GOTCHA: these bind 10.10.10.1 explicitly and fail once it is gone.
    services.router-snmp.listenAddresses = override [
      "127.0.0.1"
      "192.168.100.100"
      standbyLanAddress
    ];
    services.router-dns-service.serviceListenAddresses = override [
      "127.0.0.1"
      standbyLanAddress
    ];
  };
}
