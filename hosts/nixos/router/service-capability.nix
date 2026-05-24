{
  config,
  lib,
  ...
}:
let
  topology = config.router.topology;
  routerHost = topology.routerHost;
  haVirtualIpAddress = builtins.head (lib.splitString "/" config.services.router-ha.virtualIp);
in
{
  services.router-dns-service = {
    enable = true;
    provider = "technitium";
    serviceListenAddresses = [
      "127.0.0.1"
      haVirtualIpAddress
    ];
    searchDomains = [ topology.domain ];
    # LAN-facing DNS remains a shared clustered capability on both routers.
    # Do not casually move this behind router.failover.activeOwner: public DDNS
    # and DHCP ownership are narrower single-owner surfaces than the
    # Technitium-backed LAN resolver/admin state.
    # Advertise the router's chrony instance to LAN clients via DHCP option 42.
    # This remains the shared production identity; only the active owner should
    # actually present that identity on the production LAN.
    ntpServers = [ routerHost.ip ];
    technitium = {
      blockListPresets = [
        "hagezi-normal"
        "hagezi-nrd-14d"
      ];
      extraBlockListUrls = [ ];
      blockListUpdateIntervalHours = 24;
    };
  };

  services.router-ntp = {
    # Shared capability belongs here even if consumer-side ownership becomes
    # narrower later.
    enable = true;
    lanSubnets = [ topology.networks.lan.cidr ];
  };

  # UPnP/NAT-PMP stays declared here as shared capability wiring even if a
  # narrower failover ownership adapter is introduced later.
  services.router-upnp.enable = true;

  # NAT is handled by nftables (see role.nix).
  networking.nat.enable = false;
}
