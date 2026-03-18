{
  config,
  lib,
  pkgs,
  ...
}:

{
  networking = {
    useDHCP = true;
    useHostResolvConf = false;
  };

  systemd.network = {
    enable = true;
    wait-online.enable = true;
    networks."10-eth0" = {
      matchConfig.Name = "eth0";
      dhcpV4Config = {
        UseDNS = true;
        UseDomains = true;
        ClientIdentifier = "mac";
      };
      ipv6AcceptRAConfig.UseDNS = false;
      linkConfig.RequiredForOnline = "routable";
    };
  };

  services.resolved.enable = true;
}
