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
    enable = true;
    lanSubnets = [ topology.networks.lan.cidr ];
  };

  # UPnP/NAT-PMP should remain available on whichever router currently owns
  # the LAN path so failover does not silently drop port mapping support.
  services.router-upnp.enable = true;

  # NAT is handled by nftables (see role.nix).
  networking.nat.enable = false;
}
