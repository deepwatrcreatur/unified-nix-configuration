{ config, pkgs, lib, ... }:

{
  imports = [
    ./whitesur-theme.nix
    ./whitesur-desktops.nix
  ];

  # Configure MATE specific settings
  modules.desktop.sessions.whitesur-desktops = {
    enable = true;
  };

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

  # Packages for MATE with WhiteSur theming
  environment.systemPackages = with pkgs; [
    # Common WhiteSur desktop packages
    deskflow
    pulseaudio-ctl
    pavucontrol
    flameshot
    copyq
    dconf
    
    # MATE-specific packages
    mate.mate-settings-daemon
    ulauncher
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
