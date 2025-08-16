{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "garuda-nix";
  
  nixpkgs.hostPlatform = "x86_64-linux";

  # Enable Hyprland for the system (required for proper session files)
  programs.hyprland.enable = true;

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

    multimedia.enable = true;
    development.enable = true;
    office.enable = true;
  };

  # Define your user account
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    # initialPassword = "changeme";
  };

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
