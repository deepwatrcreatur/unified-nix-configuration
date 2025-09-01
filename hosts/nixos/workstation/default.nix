{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/wezterm-config.nix
  ];

  # Linux-specific wezterm configuration
  programs.wezterm.extraConfig = lib.mkAfter ''
    -- Default program: launch zellij with nushell as default shell (Linux path)
    config.default_prog = { '/etc/profiles/per-user/deepwatrcreatur/bin/zellij', '-l', 'welcome' }
  '';

  networking.hostName = "workstation";
  
  nixpkgs.hostPlatform = "x86_64-linux";

  # Boot loader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable AMD graphics drivers with firmware
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      amdvlk
      rocmPackages.clr.icd
    ];
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk
    ];
  };
  services.xserver.videoDrivers = [ "amdgpu" ];
  
  # Enable AMD GPU firmware
  hardware.enableRedistributableFirmware = true;
  
  # Force amdgpu driver for older AMD cards if needed
  boot.kernelParams = [ "amdgpu.si_support=1" "amdgpu.cik_support=1" ];

  # Enable KDE Plasma desktop environment
  services.xserver.enable = true;
  # services.displayManager.sddm.enable = true;
  # services.desktopManager.plasma6.enable = true;
    services.desktopManager.cosmic.enable = true;

    services.displayManager = {
      cosmic-greeter.enable = true;
      services.displayManager.gd1m.autoSuspend = false;
      autoLogin = {
        enable = true;
        user = "deepwatrcreatur";
      };
    };

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
  security.pam.services.gdm.unixAuth = true;
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  # Define your user account
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
  };

  home-manager.users.deepwatrcreatur = {
    imports = [ 
      ../../../users/deepwatrcreatur/hosts/workstation
    ];
  };

  # Additional system packages
  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.05";
}
