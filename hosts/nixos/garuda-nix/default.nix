{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "garuda-nix";
  
  nixpkgs.hostPlatform = "x86_64-linux";

  # Boot loader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable Hyprland for the system (required for proper session files)
  programs.hyprland.enable = true;

  # Enable AMD graphics drivers
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  
  # Force amdgpu driver for older AMD cards if needed
  boot.kernelParams = [ "amdgpu.si_support=1" "amdgpu.cik_support=1" ];

  # Garuda Linux configuration
  # These are the main toggles that make a system "Garuda-like"
  garuda = {
    # Enable the dr460nized desktop (KDE Plasma with Garuda theming)
    # can easily switch between Hyprland and dr460nized at the login screen
    dr460nized.enable = true;
    
    # Enable gaming optimizations and applications
    gaming.enable = true;
    
    # Performance tweaks including CachyOS kernel
    performance-tweaks = {
      cachyos-kernel = true;
      enable = true;
    };
  };

  # Enable SSH daemon
  services.openssh.enable = true;

  # Disable screen lock
  services.xserver.displayManager.gdm.autoSuspend = false;
  security.pam.services.gdm.unixAuth = true;
  services.logind.lidSwitch = "ignore";
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
    HandleSuspendKey=ignore
    HandleHibernateKey=ignore
    HandleLidSwitch=ignore
  '';

  # Define your user account
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    # initialPassword = "changeme";
  };

  # Disable garuda's home-manager to avoid conflicts
  garuda.home-manager.enable = false;
  
  home-manager.users.deepwatrcreatur = {
    imports = [ 
      ../../../users/deepwatrcreatur/hosts/garuda-nix
    ];
  };

  # Additional system packages (beyond what Garuda provides)
  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.11";
}
