# hosts/nixos/lattitude/networking.nix
{ lib, ... }:

{
  networking = {
    hostName = "lattitude";
    useNetworkd = true;
  };

  systemd.network = {
    enable = true;
    networks = {
      # Onboard Realtek Ethernet (MAC fc:15:b4:03:06:0a)
      "10-realtek-eth" = {
        matchConfig = {
          MACAddress = "fc:15:b4:03:06:0a";
        };
        address = [ "10.10.11.47/16" ];
        gateway = [ "10.10.10.1" ];
        networkConfig = {
          DHCP = "yes";
          IPv6AcceptRA = true;
          MulticastDNS = true;
          DNS = [
            "10.10.10.1"
            "1.1.1.1"
            "8.8.8.8"
          ];
          Domains = [ "deepwatercreature.com" ];
        };
        dhcpV4Config = {
          RouteMetric = 100;
          UseDNS = true;
          UseRoutes = true;
        };
        linkConfig = {
          RequiredForOnline = lib.mkForce "routable";
        };
      };
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.arp_ignore" = 1;
    "net.ipv4.conf.all.arp_announce" = 2;
  };
}
