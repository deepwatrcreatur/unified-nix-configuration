{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/nixos/common
    ../../../modules/common/utility-packages.nix
    ../../../modules/nixos/keyboard-glitches.nix # Fix stuck keyboard presses in Proxmox VM
    ../../../modules/nixos/snap.nix # Snap package manager support
    ../../../modules/activation-scripts
  ];

  # Home manager configuration for gateway
  home-manager.users.deepwatrcreatur = {
    imports = [
      ../../../users/deepwatrcreatur/hosts/gateway
    ];
  };

  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  networking.hostName = "gateway";
  networking.domain = "deepwatercreature.com";

  # Enable IP forwarding for routing
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Network interfaces
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network.enable = true;

  # WAN interface (ens17) - Get IP via DHCP
  systemd.network.networks."10-wan" = {
    matchConfig.Name = "ens17";
    networkConfig.DHCP = "yes";
    DHCPv4UseDNS = false;
  };

  # LAN interface (ens16) - Static IP for Technitium
  systemd.network.networks."20-lan" = {
    matchConfig.Name = "ens16";
    address = [ "10.10.10.1/16" ];
    networkConfig = {
      DHCPServer = "no";
    };
  };

  # Technitium DNS & DHCP Server (will be configured later after Opnsense is removed)
  services.technitium-dns-server.enable = true;

  # Firewall
  networking.nftables.enable = true;
  networking.firewall.enable = false; # Controlled by nftables

  # QEMU guest agent for Proxmox
  services.qemuGuest.enable = true;

  # SSH daemon
  services.openssh.enable = true;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
}
