{
  lib,
  ...
}:
{
  networking.hostName = lib.mkForce "router-backup";
  networking.domain = "deepwatercreature.com";

  services.router-dns-service = {
    enable = true;
    provider = "technitium";
    searchDomains = [ "deepwatercreature.com" ];
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

  networking.nat.enable = false;
}
