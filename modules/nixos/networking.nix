{ config, lib, pkgs, ... }:

{
  networking = {
    dhcpcd.enable = false;
    useDHCP = false;
    useHostResolvConf = false;
  };

  systemd.network = {
    enable = true;
    networks."50-eth0" = {
      matchConfig.Name = "eth0";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
      };
      # Only accept DNS from DHCPv4, ignore DNS from IPv6 RA
      dhcpV4Config.UseDNS = true;
      ipv6AcceptRAConfig.UseDNS = false;
      linkConfig.RequiredForOnline = "routable";
    };
  };

}
