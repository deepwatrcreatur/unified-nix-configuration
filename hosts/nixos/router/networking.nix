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

  # Stable interface names for router VM passthrough NICs.
  # Match on permanent MAC and PCI path so kernel-generated names (enp*/ens*)
  # can change without breaking the router role configuration.
  systemd.network.links = {
    "10-router-wan" = {
      matchConfig = {
        PermanentMACAddress = "02:76:c6:01:2a:b0";
        Path = "pci-0000:06:11.0";
      };
      linkConfig.Name = "router-wan";
    };
    "10-router-lan" = {
      matchConfig = {
        PermanentMACAddress = "02:76:c6:01:2a:af";
        Path = "pci-0000:06:10.0";
      };
      linkConfig.Name = "router-lan";
    };
  };
}
