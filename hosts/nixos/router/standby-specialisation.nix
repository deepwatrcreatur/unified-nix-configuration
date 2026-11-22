{ lib, ... }:
# Manual failover: `standby` hands the router role to elitedesk without a
# redeploy. Activate with
#   sudo /run/current-system/specialisation/standby/bin/switch-to-configuration test
# and return with
#   sudo /run/current-system/bin/switch-to-configuration test
# `test` never changes the boot entry, so a reboot always comes back as the
# primary. Procedure: nix-clan-homelab docs/router-failover.md.
let
  # WHY: free LAN address for the demoted router; 10.10.10.1 moves to
  # elitedesk, which also keeps its own 10.10.10.4.
  standbyLanAddress = "10.10.10.2";
  gateway = "10.10.10.1";
  # WHY: role.nix forces these with mkForce (priority 50); the specialisation
  # must win over it.
  override = lib.mkOverride 40;
in
{
  specialisation.standby.configuration = {
    system.nixos.tags = [ "standby" ];

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
