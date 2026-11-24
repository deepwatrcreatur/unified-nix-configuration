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
  # WHY: only a reply from elitedesk's LAN port counts as "the peer holds the
  # gateway"; any other LAN device answering must not demote the router.
  peerLanMac = "ec:0d:9a:49:a8:1e";
  stateDir = "/var/lib/router-failover";
  # INVARIANT: written by standby activation and removed only by a deliberate
  # return to primary (switch or test), so a reset of the demoted router
  # cannot bring it back as a second gateway (rehearsal 1, nch-sny.36.2).
  demotedMarker = "${stateDir}/demoted";
  # This boot is demoted (persistent marker, or the peer answered for the
  # gateway); gated units and the standby resume key off this file.
  bootDemoted = "/run/router-failover/demoted";
  networkDir = "/etc/systemd/network";
  addedList = "${stateDir}/added-network-files";

  bootGuard = pkgs.writeShellScript "router-failover-boot-guard" ''
    set -u
    PATH=${lib.makeBinPath [ pkgs.coreutils pkgs.gnugrep pkgs.iproute2 pkgs.iputils config.systemd.package ]}
    # INVARIANT: acts only while the system boots. A live switch to standby
    # writes the marker first; acting then re-pointed links at an older
    # booted system's files and failed the switch (rehearsal 3).
    state="$(systemctl is-system-running 2>/dev/null || true)"
    case "$state" in
      initializing|starting) ;;
      *) exit 0 ;;
    esac
    standby=/run/booted-system/specialisation/standby/etc/systemd/network
    reason=""
    if [ -e ${demotedMarker} ]; then
      reason="${demotedMarker} exists"
    elif ip link show ${lanDevice} >/dev/null 2>&1; then
      ip link set ${lanDevice} up
      for _ in $(seq 1 20); do
        [ "$(cat /sys/class/net/${lanDevice}/carrier 2>/dev/null)" = 1 ] && break
        sleep 0.25
      done
      if arping -D -c 2 -w 3 -I ${lanDevice} ${gateway} 2>/dev/null \
        | grep -qiF '[${peerLanMac}]'; then
        reason="elitedesk (${peerLanMac}) answers for ${gateway}"
      fi
    fi
    [ -n "$reason" ] || exit 0

    echo "router-failover: booting demoted: $reason" >&2
    install -d -m 0755 /run/router-failover
    touch ${bootDemoted} || exit 1
    if [ ! -d "$standby" ]; then
      echo "router-failover: $standby missing; cannot apply standby networking" >&2
      exit 1
    fi
    # GOTCHA: networkd gives /etc priority over /run for files of the same
    # name, so re-point the per-file links in ${networkDir} at the standby
    # specialisation's files. Every activation re-links them to /etc/static,
    # so a later reboot or switch restores the primary files by itself.
    for f in ${networkDir}/*; do
      name="$(basename "$f")"
      if [ -L "$f" ] && [ ! -e "$standby/$name" ]; then
        rm -f "$f"
      fi
    done
    for f in "$standby"/*; do
      name="$(basename "$f")"
      ln -sfn "$(readlink -f "$f")" "${networkDir}/$name"
      # WHY: setup-etc only removes stale links into /etc/static; record
      # standby-only files so primary activation can remove them.
      if [ ! -e "/etc/static/systemd/network/$name" ]; then
        install -d -m 0755 ${stateDir}
        echo "$name" >> ${addedList}
      fi
    done
  '';

  # Single-active LAN services that must not start on a demoted boot.
  gatedUnits = lib.filter (u: u.on) [
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
          ] ++ map (u: "${u.name}.service") gatedUnits;
          conflicts = [ "shutdown.target" ];
          # WHY: a role switch must not re-run the guard (see INVARIANT above).
          restartIfChanged = false;
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

        # WHY: the guard only fixed networking; activate the full standby
        # specialisation once boot settles, outside the boot transaction.
        router-failover-resume-standby = {
          description = "Finish a demoted boot in the standby specialisation";
          wantedBy = [ "multi-user.target" ];
          after = [ "multi-user.target" ];
          unitConfig.ConditionPathExists = bootDemoted;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${config.systemd.package}/bin/systemd-run --no-block --on-active=5 --unit=router-failover-activate-standby /run/current-system/specialisation/standby/bin/switch-to-configuration test";
          };
        };
      }
    ]
    ++ map (u: { ${u.name}.unitConfig.ConditionPathExists = "!${bootDemoted}"; }) gatedUnits
  );

  # GOTCHA: boot runs activation without NIXOS_ACTION; only a deliberate
  # switch or test to primary clears the markers. Runs after "etc", which has
  # already re-linked ${networkDir} to the primary files; reload networkd in
  # case the old and new systems are identical and nothing else restarts it.
  system.activationScripts.routerFailoverRole = lib.stringAfter [ "etc" ] ''
    if [ -f ${addedList} ]; then
      while read -r name; do
        [ -n "$name" ] && rm -f "${networkDir}/$name"
      done < ${addedList}
      rm -f ${addedList}
    fi
    case "''${NIXOS_ACTION:-}" in
      switch|test)
        if [ -e ${demotedMarker} ] || [ -e ${bootDemoted} ]; then
          rm -f ${demotedMarker} ${bootDemoted}
          ${config.systemd.package}/bin/networkctl reload || true
        fi
        ;;
    esac
  '';

  specialisation.standby.configuration = {
    system.nixos.tags = [ "standby" ];

    system.activationScripts.routerFailoverRole = lib.mkForce ''
      install -d -m 0755 ${stateDir} /run/router-failover
      touch ${demotedMarker} ${bootDemoted}
    '';
    systemd.services.router-failover-resume-standby.enable = lib.mkForce false;

    # INVARIANT: the modem has one lease; the WAN must be down before
    # elitedesk brings its WAN up with this router's MAC and DUID.
    systemd.network.networks."10-router-wan-primary".linkConfig.ActivationPolicy = override "always-down";

    # GOTCHA: 20-router-lan (from routedInterfaces.lan) is the file networkd
    # applies to the LAN. role.nix's 08-router-parent file has no [Match]
    # section and is ignored, so overrides there had no effect (rehearsal 2:
    # the demoted router kept advertising itself and had no default route).
    services.router-networking.routedInterfaces.lan = {
      ipv4Address = override "${standbyLanAddress}/16";
      # WHY: stopping sd-radv sends a final RA with lifetime 0, so clients
      # drop this router as their IPv6 default route at once.
      ipv6SendRA = override false;
      dhcpPrefixDelegation = override false;
    };
    # WHY: Tailscale and other outbound traffic leave through elitedesk.
    systemd.network.networks."20-router-lan".gateway = [ gateway ];
    # SECURITY: defensive; if the parent file ever gains a [Match], it must
    # not put the gateway address on the demoted router.
    systemd.network.networks."08-router-parent-enp6s16".address = override [ "${standbyLanAddress}/16" ];

    # WHY: the WAN is down by design; these probes would restart-loop and
    # fail every standby activation.
    systemd.services.health-wan-carrier.enable = override false;
    systemd.services.health-wan-ip.enable = override false;

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
