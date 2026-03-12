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
    ./networking.nix
    ./nftables.nix
    ./router-optimizations.nix
    ./router-dashboard.nix
    ./nginx-proxy-manager.nix
    ../../../modules/nixos/common
    ../../../modules/common/utility-packages.nix
    ../../../modules/nixos/keyboard-glitches.nix # Fix stuck keyboard presses in Proxmox VM
    ../../../modules/nixos/snap.nix # Snap package manager support
    ../../../modules/activation-scripts
    inputs.agenix.nixosModules.default # Agenix secrets management
  ];

  # Home manager configuration for gateway
  home-manager.users.deepwatrcreatur = {
    imports = [
      ../../../modules/home-manager/git.nix
      ../../../modules/home-manager/gpg-cli.nix
      ../../../users/deepwatrcreatur/hosts/gateway
    ];
    
    home.username = "deepwatrcreatur";
    home.homeDirectory = "/home/deepwatrcreatur";
    programs.home-manager.enable = true;
  };

  home-manager.extraSpecialArgs.hostName = "gateway";
  home-manager.extraSpecialArgs.isDesktop = false;

  # Boot loader (GRUB for MBR/BIOS)
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";  # Install GRUB on the disk
  boot.loader.timeout = 5;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Technitium DNS & DHCP Server
  services.technitium-dns-server.enable = true;
  
  # Nginx Proxy Manager for reverse proxy
  services.nginx-proxy-manager.enable = true;
  
  # Enable podman for containers (required by NPM)
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  virtualisation.oci-containers.backend = "podman";
  
  # QEMU guest agent for Proxmox
  services.qemuGuest.enable = true;

  # SSH daemon
  services.openssh = {
    enable = true;
    permitRootLogin = "prohibit-password"; # Secure default
    extraConfig = ''
      Match Address 10.10.10.0/24
        PermitRootLogin yes
    '';
  };
  
  # Fail2ban for SSH brute-force protection
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.1/8"
      "10.10.0.0/16"  # LAN network
    ];
  };

  # Define your user account (SSH keys managed by common/ssh-keys.nix)
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
    ];
    shell = pkgs.fish;
  };

  services.ssh-keys-manager.username = "deepwatrcreatur";

  # Enable fish shell
  programs.fish.enable = true;
  
  # Allow wheel group to use sudo without password
  security.sudo.wheelNeedsPassword = false;

  # Mount the 10GB spinning disk for log files
  fileSystems."/var/log/technitium" = {
    device = "/dev/sda";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };

  environment.systemPackages = with pkgs; [
    tmux
  ];

  # Agenix configuration
  age.secrets.technitium-api-key = {
    file = ../../../secrets-agenix/technitium-api-key.age;
    owner = "deepwatrcreatur";
    group = "users";
  };
  
  environment.variables.TECHNITIUM_API_KEY_FILE = config.age.secrets.technitium-api-key.path;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.05";
}
