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

  # NAT is handled by nftables (see nftables.nix)
  networking.nat.enable = false;

  # Stable interface names for router and router-backup VMs.
  # Match on NIC MAC addresses so kernel-generated names (enp*, ens*)
  # can change without breaking the router role configuration.
  systemd.network.links = {
    "10-router-lan" = {
      matchConfig.MACAddress = "02:76:c6:01:2a:af";
      linkConfig.Name = "lan0";
    };
    "10-router-wan" = {
      matchConfig.MACAddress = "02:76:c6:01:2a:b0";
      linkConfig.Name = "wan0";
    };
  };
}
