{
  config,
  lib,
  pkgs,
  ...
}:

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
      dhcpV4Config = {
        UseDNS = true;
        UseDomains = true; # Use search domain from DHCP
        # Use MAC address as client identifier for DHCP static lease matching
        ClientIdentifier = "mac";
      };
      ipv6AcceptRAConfig.UseDNS = false;
      linkConfig.RequiredForOnline = "routable";
    };
  };

}
