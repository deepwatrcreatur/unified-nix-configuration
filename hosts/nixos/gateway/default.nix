{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos/common
  ];

  networking.hostName = "gateway";
  networking.domain = "deepwatercreature.com";

  # User configuration
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Turn on IP forwarding for routing
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Network interfaces
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network.enable = true;

  # WAN interface
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "igb0"; # Adjust if different in Proxmox VM (e.g. eth0, ens18)
    networkConfig.DHCP = "yes";
  };

  # LAN interface
  systemd.network.networks."20-lan" = {
    matchConfig.Name = "igb1"; # Adjust if different in Proxmox VM (e.g. eth1, ens19)
    address = [ "10.10.10.1/16" ];
    networkConfig = {
      DHCPServer = "no";
    };
  };

  # NAT configuration
  networking.nat = {
    enable = true;
    externalInterface = "igb0";
    internalInterfaces = [ "igb1" ];
    forwardPorts = [
      {
        destination = "10.10.11.69:80";
        proto = "tcp";
        sourcePort = 80;
      }
      {
        destination = "10.10.11.69:443";
        proto = "tcp";
        sourcePort = 443;
      }
      # WebGUI forwarding is omitted as NixOS router doesn't need it on 8443
    ];
  };

  # Firewall rules
  networking.firewall.interfaces."igb1".allowedTCPPorts = [ 53 80 443 22 ];
  networking.firewall.interfaces."igb1".allowedUDPPorts = [ 53 67 68 ];

  # DNS server (Unbound)
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [ "0.0.0.0" "::0" ];
        access-control = [ "10.10.0.0/16 allow" "127.0.0.0/8 allow" ];
        local-zone = [ "deepwatercreature.com. transparent" ];
      };
      forward-zone = [
        {
          name = ".";
          forward-addr = [ "1.1.1.1" "8.8.8.8" ];
        }
      ];
    };
  };

  # DHCP server (Kea)
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [ "igb1" ];
      };
      lease-database = {
        name = "/var/lib/kea/dhcp4.leases";
        persist = true;
        type = "memfile";
      };
      valid-lifetime = 4000;
      subnet4 = [
        {
          subnet = "10.10.0.0/16";
          pools = [ { pool = "10.10.10.10 - 10.10.10.245"; } ];
          option-data = [
            { name = "routers"; data = "10.10.10.1"; }
            { name = "domain-name-servers"; data = "10.10.10.1"; }
            { name = "domain-name"; data = "deepwatercreature.com"; }
          ];
          reservations = [
            { hw-address = "ec:71:db:c6:f4:f3"; ip-address = "10.10.10.59"; hostname = "418"; }
            { hw-address = "ec:71:db:1f:af:ab"; ip-address = "10.10.10.60"; hostname = "420"; }
            { hw-address = "f0:92:1c:cc:57:00"; ip-address = "10.10.10.70"; }
            { hw-address = "14:18:77:15:97:e8"; ip-address = "10.10.10.79"; }
            { hw-address = "e0:46:9a:42:40:4a"; ip-address = "10.10.10.80"; hostname = "netgear"; }
            { hw-address = "00:1c:10:5f:91:a0"; ip-address = "10.10.10.81"; }
            { hw-address = "90:e2:ba:6c:e0:48"; ip-address = "10.10.10.88"; hostname = "pmoxb650"; }
            { hw-address = "bc:24:11:b0:5c:fb"; ip-address = "10.10.10.131"; hostname = "inference1"; }
            { hw-address = "bc:24:11:26:b0:f1"; ip-address = "10.10.10.132"; hostname = "inference2"; }
            { hw-address = "38:18:4c:13:18:75"; ip-address = "10.10.10.160"; }
            { hw-address = "28:cf:51:91:e5:59"; ip-address = "10.10.10.161"; hostname = "Switch"; }
            { hw-address = "38:b1:db:3d:45:05"; ip-address = "10.10.10.162"; hostname = "tvdda730035299"; }
            { hw-address = "54:44:a3:e1:03:b0"; ip-address = "10.10.10.163"; hostname = "Samsung"; }
            { hw-address = "a8:23:fe:dd:04:72"; ip-address = "10.10.10.174"; hostname = "LGwebOSTV"; }
            { hw-address = "a8:5b:f7:c2:0a:42"; ip-address = "10.10.10.212"; hostname = "AP22---Nosheen-living-room"; }
            { hw-address = "54:d7:e3:c7:51:80"; ip-address = "10.10.10.213"; hostname = "Anwer-living-room"; }
            { hw-address = "fc:7f:f1:cc:e1:ca"; ip-address = "10.10.10.214"; hostname = "AP11---NosheenBedroom"; }
            { hw-address = "00:26:bb:6d:fb:4e"; ip-address = "10.10.10.219"; hostname = "anwers-time-capsule"; }
            { hw-address = "a8:51:ab:9f:74:33"; ip-address = "10.10.10.231"; hostname = "Anwers-Room"; }
            { hw-address = "28:ff:3c:a3:51:7e"; ip-address = "10.10.10.233"; hostname = "kitchen"; }
            { hw-address = "6c:4a:85:4f:2b:58"; ip-address = "10.10.10.233"; hostname = "Living-Room"; }
            { hw-address = "10:ce:02:6c:70:53"; ip-address = "10.10.10.243"; }
            { hw-address = "90:23:5b:93:49:b1"; ip-address = "10.10.10.244"; }
            { hw-address = "b0:73:9c:ba:95:28"; ip-address = "10.10.10.246"; }
            { hw-address = "58:9a:3e:71:75:73"; ip-address = "10.10.10.247"; }
            { hw-address = "50:07:c3:4f:e3:60"; ip-address = "10.10.10.248"; }
            { hw-address = "74:d4:23:63:6f:d3"; ip-address = "10.10.10.249"; }
            { hw-address = "88:c9:e8:30:9c:a9"; ip-address = "10.10.11.50"; hostname = "SonyOLED42"; }
            { hw-address = "bc:24:11:7c:a1:ee"; ip-address = "10.10.11.50"; hostname = "infisical"; }
            { hw-address = "bc:24:11:72:52:ef"; ip-address = "10.10.11.51"; hostname = "cache"; }
            { hw-address = "bc:24:11:ba:17:42"; ip-address = "10.10.11.62"; hostname = "nixos-lxc"; }
            { hw-address = "bc:24:11:15:b0:27"; ip-address = "10.10.11.63"; hostname = "nixos-base"; }
            { hw-address = "bc:24:11:9c:2d:89"; ip-address = "10.10.11.69"; hostname = "homeserver"; }
            { hw-address = "bc:24:11:4f:1b:d6"; ip-address = "10.10.11.70"; hostname = "casaos"; }
            { hw-address = "bc:24:11:f5:ba:ca"; ip-address = "10.10.11.77"; hostname = "casaos"; }
            { hw-address = "bc:24:11:5e:2b:9b"; ip-address = "10.10.11.88"; hostname = "fedora"; }
            { hw-address = "bc:24:11:a9:86:aa"; ip-address = "10.10.11.88"; hostname = "homeserver"; }
            { hw-address = "a2:b0:e2:91:2b:f4"; ip-address = "10.10.11.90"; hostname = "iPadProM1"; }
            { hw-address = "d0:11:e5:3b:51:c3"; ip-address = "10.10.11.149"; hostname = "macminim4"; }
            { hw-address = "9c:ad:ef:10:c7:3e"; ip-address = "10.10.13.9"; hostname = "OBi100"; }
            { hw-address = "64:16:7f:97:e4:f6"; ip-address = "10.10.13.13"; hostname = "Polycom_64167f97e4f6"; }
            { hw-address = "64:16:7f:98:46:56"; ip-address = "10.10.13.14"; hostname = "Polycom_64167f984656"; }
            { hw-address = "00:04:f2:34:71:b3"; ip-address = "10.10.13.16"; }
            { hw-address = "00:04:f2:34:67:ae"; ip-address = "10.10.13.17"; }
            { hw-address = "90:9a:4a:4a:d4:49"; ip-address = "10.10.14.10"; hostname = "HS300"; }
            { hw-address = "50:c7:bf:6b:d8:f8"; ip-address = "10.10.14.12"; hostname = "HS110"; }
            { hw-address = "50:c7:bf:00:03:77"; ip-address = "10.10.14.13"; hostname = "HS110"; }
            { hw-address = "5c:62:8b:d8:69:fa"; ip-address = "10.10.14.15"; hostname = "KP303"; }
            { hw-address = "50:91:e3:74:33:e9"; ip-address = "10.10.14.16"; hostname = "KP125M"; }
            { hw-address = "30:de:4b:25:7b:47"; ip-address = "10.10.14.18"; hostname = "KP405"; }
            { hw-address = "34:60:f9:87:02:85"; ip-address = "10.10.14.19"; hostname = "KP405"; }
            { hw-address = "48:b4:23:b4:2c:ff"; ip-address = "10.10.14.22"; hostname = "AmazonPlug17GJ"; }
            { hw-address = "a8:e6:21:76:ff:cd"; ip-address = "10.10.14.23"; hostname = "AmazonPlug11V8"; }
            { hw-address = "f0:27:2d:8e:b1:22"; ip-address = "10.10.14.24"; hostname = "amazon-c80d810ff"; }
            { hw-address = "cc:33:31:1a:fe:c9"; ip-address = "10.10.15.10"; hostname = "Lutron-067f7e1f"; }
            { hw-address = "e0:92:8f:4e:c7:ae"; ip-address = "10.10.15.11"; hostname = "Lutron-067d1617"; }
            { hw-address = "08:3a:8d:cf:5a:42"; ip-address = "10.10.15.18"; hostname = "SwitchBot"; }
            { hw-address = "24:58:7c:06:fc:ec"; ip-address = "10.10.15.19"; hostname = "SwitchBot-HubMiniMatter-06FCEC"; }
            { hw-address = "d4:ad:fc:ea:99:9f"; ip-address = "10.10.15.181"; hostname = "goveesmartbulb1"; }
            { hw-address = "d4:ad:fc:f2:3c:0a"; ip-address = "10.10.15.182"; hostname = "goveesmartbulb2"; }
            { hw-address = "d4:ad:fc:e8:80:76"; ip-address = "10.10.15.183"; hostname = "goveesmartbulb3"; }
          ];
        }
      ];
    };
  };

  system.stateVersion = "25.05";
}
