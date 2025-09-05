# hosts/nixos_lxc/cache-build-server/default.nix - NixOS Build Server Configuration
{ config, pkgs, inputs, lib, ... }:
{
  imports = [
    ../../../../modules/nixos
    ../../../../modules/nixos/lxc-nixos.nix
  ];

  networking.hostName = "cache";
  networking.domain = "deepwatercreature.com";

  nixpkgs.hostPlatform = "x86_64-linux";

  # LXC Container optimizations
  boot.isContainer = true;
  boot.loader.initScript.enable = true;

  # Networking for LXC
  #networking.useDHCP = false;
  networking.useNetworkd = false;
  networking.interfaces.eth0.useDHCP = true;

  # Build server specific configuration
  nix = {
    settings = {
      # Optimize for building
      max-jobs = "auto";
      cores = 0; # Use all available cores
      
      # Build server optimizations
      builders-use-substituters = true;
      substitute = true;
      trusted-users = [ "root" "@wheel" ];
      
      # Enable flakes and new nix commands
      experimental-features = [ "nix-command" "flakes" ];
      
      # Build cache settings
      keep-outputs = true;
      keep-derivations = true;
      
      # Increase build timeout for large packages
      timeout = 3600; # 1 hour
    };
    
    # Enable garbage collection
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
  };

  # Build server packages
  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    iotop
    lsof
    strace
    # Build tools
    gcc
    binutils
    gnumake
    # Archive tools
    gzip
    bzip2
    xz
    # Network tools
    curl
    wget
    rsync
  ];

  # SSH for remote builds
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
    };
  };

  # User configuration
  users.users.nixbuilder = {
    isSystemUser = true;
    group = "nixbuilder";
    home = "/var/lib/nixbuilder";
    createHome = true;
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx your-key"
    ];
  };
  
  users.groups.nixbuilder = {};

  # System user for builds  
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here
      # "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx your-key"
    ];
  };

  # Security
  security.sudo.wheelNeedsPassword = false;

  # Firewall - only SSH and any build cache ports
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # System monitoring
  services.journald.extraConfig = ''
    SystemMaxUse=1G
    MaxRetentionSec=1month
  '';

}
