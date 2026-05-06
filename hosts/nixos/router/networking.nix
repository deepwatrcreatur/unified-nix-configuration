{
  config,
  ...
}:
let
  topology = config.router.topology;
  routerHost = topology.routerHost;
in
{
  networking.hostName = "router";
  networking.domain = topology.domain;

  services.router-dns-service = {
    enable = true;
    provider = "technitium";
    searchDomains = [ topology.domain ];
    # Advertise the router's chrony instance to all LAN clients via DHCP option 42.
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

  # NTP server — serves LAN clients (advertised via DHCP option 42 above).
  services.router-ntp = {
    enable = true;
    lanSubnets = [ topology.networks.lan.cidr ];
  };

  # NAT is handled by nftables (see nftables.nix)
  networking.nat.enable = false;
}
