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
    email_address = "deepwatrcreatur@gmail.com";
    theme = "tokyo-night"; # Options: tokyo-night, catppuccin, nord, etc.
    
    # Optional: Enable specific omarchy features
    # Check the omarchy-nix repository config.nix for all available options:
    # https://github.com/henrysipp/omarchy-nix/blob/main/config.nix
  };

  # Enable Hyprland (omarchy-nix provides its own Hyprland config)
  programs.hyprland.enable = true;

  # Enable AMD graphics drivers
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  
  # Force amdgpu driver for older AMD cards if needed
  boot.kernelParams = [ "amdgpu.si_support=1" "amdgpu.cik_support=1" ];

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

  # Enable SSH daemon
  services.openssh.enable = true;

  # Disable screen lock
  services.displayManager.gdm.autoSuspend = false;
  security.pam.services.gdm.unixAuth = true;
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandleSuspendKey = "ignore";
    HandleHibernateKey = "ignore";
    HandleLidSwitch = "ignore";
  };

  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
  ];

  system.stateVersion = "24.11";
}
