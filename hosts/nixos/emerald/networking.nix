{ lib, ... }:

{
  networking = {
    hostName = "emerald";
    useNetworkd = true;
  };

  systemd.network = {
    enable = true;
    networks = {
      # 5GbE Realtek onboard interface (enp9s0, MAC 34:5a:60:01:5e:f8)
      # Primary physical network interface on MSI Tomahawk.
      "10-realtek-5g" = {
        matchConfig = {
          MACAddress = "34:5a:60:01:5e:f8";
        };
        networkConfig = {
          DHCP = "ipv6";
          IPv6AcceptRA = true;
          MulticastDNS = true;
          DNS = [
            "10.10.10.1"
            "1.1.1.1"
            "8.8.8.8"
          ];
          Domains = [ "deepwatercreature.com" ];
        };
        address = [
          "10.10.11.55/16"
        ];
        routes = [
          {
            Gateway = "10.10.10.1";
            GatewayOnLink = true;
            Metric = 100;
          }
        ];
        linkConfig = {
          RequiredForOnline = lib.mkForce "routable";
        };
      };

      # Deprioritize/disable secondary physical ethernet interfaces (e.g. 10Gb card before replacement with GPU)
      # to prevent ARP flux and conflicting DHCP leases on 10.10.0.0/16
      "50-ethernet" = {
        networkConfig = {
          DHCP = lib.mkForce "no";
          IPv6AcceptRA = lib.mkForce false;
        };
        linkConfig = {
          RequiredForOnline = lib.mkForce "no";
        };
      };
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.arp_ignore" = 1;
    "net.ipv4.conf.all.arp_announce" = 2;
  };
}
