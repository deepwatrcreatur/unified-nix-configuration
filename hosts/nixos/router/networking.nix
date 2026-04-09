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

  services.router-technitium.scopes = {
    LAN = {
      legacyNames = [ "Default" ];
      startingAddress = "10.10.10.100";
      endingAddress = "10.10.10.250";
      subnetMask = "255.255.0.0";
      routerAddress = routerHost.ip;
      domainName = topology.domain;
      domainSearchList = [ topology.domain ];
      useThisDnsServer = true;
      ntpServers = [ routerHost.ip ];
      # Many Wi-Fi and mobile clients now use locally administered/randomized
      # MACs; blocking them causes silent "no lease" failures.
      blockLocallyAdministeredMacAddresses = false;
      ignoreClientIdentifierOption = true;
      enabled = true;
    };
  };

  # NAT is handled by nftables (see nftables.nix)
  networking.nat.enable = false;
}
