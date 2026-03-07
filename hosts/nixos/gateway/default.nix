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
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # MBR install for SeaBIOS

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
  networking.nftables.enable = true;
  networking.firewall.interfaces."igb1".allowedTCPPorts = [ 53 80 443 22 5380 ];
  networking.firewall.interfaces."igb1".allowedUDPPorts = [ 53 67 68 ];

  # Technitium DNS & DHCP Server
  services.technitium-dns-server.enable = true;

  system.stateVersion = "25.05";
}
