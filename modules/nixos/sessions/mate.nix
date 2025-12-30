{ config, pkgs, lib, ... }:

{
  # Enable X11 windowing system.
  services.xserver.enable = true;

  # Enable MATE desktop environment.
  services.xserver.desktopManager.mate.enable = true;

  # Configure autorepeat for Proxmox guest to prevent stuck keypresses
  services.xserver.autoRepeatDelay = 300;
  services.xserver.autoRepeatInterval = 40;

  # Enable LightDM display manager for MATE
  services.xserver.displayManager.lightdm.enable = true;

  # Enable autologin
  services.displayManager.autoLogin = {
    enable = true;
    user = "deepwatrcreatur";
  };

  # Import Shared WhiteSur Theme Module
  imports = [
    ./whitesur-theme.nix
  ];

  # MATE-Specific Packages
  environment.systemPackages = with pkgs; [
    # MATE-specific settings plugins
    mate.mate-settings-daemon
    
    # Application launcher - Ulauncher (similar to Spotlight/Alfred)
    ulauncher
    deskflow
    
    # Audio system tools for macOS-like volume control
    pulseaudio-ctl
    pavucontrol  # Audio GUI similar to macOS audio preferences
    
    # Additional tools for macOS-like workflow
    flameshot  # Screenshot tool similar to macOS
    copyq  # Clipboard manager (macOS-like clipboard history)
    
    # Compositor for transparency effects
    picom
    
    # Configuration tools
    dconf  # Settings backend
  ];

  # XDG Portals for MATE
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-mate
    ];
  };

  # Ulauncher Configuration
  systemd.user.services.ulauncher = lib.mkIf config.services.xserver.enable {
    description = "Ulauncher application launcher";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.ulauncher}/bin/ulauncher --hide-window";
      Restart = "on-failure";
    };
  };

  # Auto-start MATE desktop configuration
  systemd.user.services.mate-config = lib.mkIf config.services.xserver.enable {
    description = "Configure MATE for macOS-like behavior";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash ${./mate/mate-config.sh}";
      RemainAfterExit = true;
    };
  };

  # Compositor for macOS-like Transparency Effects
  services.picom = {
    enable = true;
    fade = true;
    fadeDelta = 5;
    fadeSteps = [ 0.01 0.0125 ];
    shadow = true;
    shadowOffsets = [ (-15) (-15) ];
    shadowOpacity = 0.25;
    backend = "glx";
    vSync = true;
  };

  # Touchpad Configuration for macOS-like Gestures
  services.libinput = {
    enable = true;
    touchpad = {
      tapping = true;
      naturalScrolling = true;  # macOS-like scrolling
      clickMethod = "clickfinger";
    };
  };

  # System message on first login
  system.activationScripts.mateMacosSetup = lib.mkAfter ''
    mkdir -p /etc/mate-macos-config
    echo "macOS-like MATE configuration initialized" > /etc/mate-macos-config/status
    echo "Theme settings configured via Home Manager (modules/home-manager/mate.nix)" >> /etc/mate-macos-config/status
  '';
}
