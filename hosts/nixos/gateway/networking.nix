# Gateway-specific network defaults layered on top of nix-router-optimized's
# reusable router-networking module.
{
  ...
}:

{
  networking.hostName = "gateway";
  networking.domain = "deepwatercreature.com";

  services.router-dns-service = {
    enable = true;
    provider = "technitium";
    searchDomains = [ "deepwatercreature.com" ];
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
