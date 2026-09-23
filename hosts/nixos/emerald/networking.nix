{ lib, ... }:

{
  networking = {
    hostName = "emerald";
    useNetworkd = true;
  };

  systemd.network = {
    enable = true;
    networks = {
      # 5GbE Realtek onboard interface (MAC 34:5a:60:01:5e:f8)
      # Primary physical network interface on MSI Tomahawk.
      # Obtains 10.10.11.55 via DHCP reservation on router.
      "10-realtek-5g" = {
        matchConfig = {
          MACAddress = "34:5a:60:01:5e:f8";
        };
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
