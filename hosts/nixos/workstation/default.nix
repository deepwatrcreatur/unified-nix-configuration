{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/wezterm-config.nix
    ../../../modules/nixos/garuda-themed-kde.nix
  ];

  # Linux-specific wezterm configuration
  programs.wezterm.extraConfig = lib.mkAfter ''
    -- Default program: launch zellij with nushell as default shell (Linux path)
    config.default_prog = { '/etc/profiles/per-user/deepwatrcreatur/bin/zellij', '-l', 'welcome' }
  '';

  networking.hostName = "workstation";
  
  nixpkgs.hostPlatform = "x86_64-linux";

  # Boot loader configuration
  boot.loader.limine.enable = true;
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

  # Enable X11 for KDE
  services.xserver.enable = true;

  services.displayManager = {
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

  services.tailscale.enable = true;
   
  # Disable screen lock
  security.pam.services.gdm.unixAuth = true;
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  security.sudo.wheelNeedsPassword = false;
  
  # Define your user account
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.nushell;
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
