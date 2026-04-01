{
  ...
}:

{
  networking.hostName = "router";
  networking.domain = "deepwatercreature.com";

  services.router-dns-service = {
    enable = true;
    provider = "technitium";
    searchDomains = [ "deepwatercreature.com" ];
    # Advertise the router's chrony instance to all LAN clients via DHCP option 42.
    ntpServers = [ "10.10.10.1" ];
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
}
