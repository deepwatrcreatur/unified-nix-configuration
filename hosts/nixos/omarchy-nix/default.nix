{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "omarchy-nix";
  
  nixpkgs.hostPlatform = "x86_64-linux";

  # Boot loader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Configure omarchy-nix specific settings
  omarchy = {
    # Replace with your actual details
    full_name = "Anwer Khan";
    email_address = "anwer@deepwatercreature.com";
    theme = "tokyo-night"; # Options: tokyo-night, catppuccin, nord, etc.
    
    # Optional: Enable specific omarchy features
    # Check the omarchy-nix repository config.nix for all available options:
    # https://github.com/henrysipp/omarchy-nix/blob/main/config.nix
  };

  # Enable Hyprland (omarchy-nix provides its own Hyprland config)
  programs.hyprland.enable = true;

  home-manager.users.deepwatrcreatur = {
    imports = [ 
      inputs.omarchy-nix.homeManagerModules.default 
      ../../../users/deepwatrcreatur/hosts/omarchy-nix
    ];
  };

  # Note: omarchy-nix provides its own display manager and desktop configuration
  
  # Enable sound
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable networking
  networking.networkmanager.enable = true;

  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
  ];

  system.stateVersion = "24.11";
}
