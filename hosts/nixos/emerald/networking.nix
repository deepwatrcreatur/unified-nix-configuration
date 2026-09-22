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
          DHCP = "yes";
          IPv6AcceptRA = true;
          MulticastDNS = true;
          DNS = [ "10.10.10.1" ];
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
        dhcpV4Config = {
          RouteMetric = 100;
          UseDNS = true;
          UseRoutes = true;
        };
        linkConfig = {
          RequiredForOnline = lib.mkForce "routable";
        };
      };

      # Deprioritize any secondary physical ethernet interfaces (e.g. 10Gb card before replacement with GPU)
      "50-ethernet" = {
        dhcpV4Config = {
          RouteMetric = lib.mkForce 1024;
        };
        linkConfig = {
          RequiredForOnline = lib.mkForce "no";
        };
      };
    };
  };
}
