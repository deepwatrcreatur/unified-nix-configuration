{ lib, ... }:

{
  networking.useNetworkd = lib.mkForce true;
  networking.useDHCP = lib.mkForce false;
  networking.useHostResolvConf = false;

  systemd.network = {
    enable = true;
    wait-online.enable = true;

    links."10-vaglio-lan0" = {
      matchConfig.MACAddress = "BC:24:11:A4:02:7A";
      linkConfig.Name = "lan0";
    };

    networks."10-lan0" = {
      matchConfig.Name = "lan0";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
      };
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
