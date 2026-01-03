{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./whitesur-theme.nix
  ];

  services.desktopManager.cosmic.enable = true;

  services.displayManager.cosmic-greeter.enable = true;

  # Enable GNOME Keyring for secure credential storage (needed by Mailspring and other apps)
  services.gnome.gnome-keyring.enable = true;

  # Compositor for macOS-like transparency effects
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

  # Touchpad configuration for macOS-like gestures
  services.libinput = {
    enable = true;
    touchpad = {
      tapping = true;
      naturalScrolling = true;
      clickMethod = "clickfinger";
    };
  };

  # System packages for COSMIC with WhiteSur theming
  environment.systemPackages = with pkgs; [
    deskflow
    pulseaudio-ctl
    pavucontrol
    flameshot
    copyq
    dconf
    ulauncher
    plank
  ];

  # Enable XDG portals for COSMIC
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-cosmic
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    # Portal configuration for COSMIC with workarounds:
    # - ScreenCast: Use gtk backend (cosmic's implementation has issues)
    # - InputCapture: Use gnome backend (cosmic doesn't implement it yet)
    #   This is required for Deskflow/Input Leap to work on Wayland
    config = {
      common = {
        "org.freedesktop.impl.portal.ScreenCast" = "gtk";
        "org.freedesktop.impl.portal.InputCapture" = "gnome";
        "org.freedesktop.impl.portal.RemoteDesktop" = "gnome";
      };
    };
  };

  # Ulauncher application launcher
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

  # Auto-start COSMIC configuration for workspace switcher and transparent panel
  systemd.user.services.cosmic-config = lib.mkIf config.services.xserver.enable {
    description = "Configure COSMIC for macOS-like behavior";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 2 && gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false || true'";
      RemainAfterExit = true;
    };
  };

  # Plank dock service for COSMIC - macOS-like transparent dock on the right side
  systemd.user.services.plank = lib.mkIf config.services.xserver.enable {
    description = "Plank macOS-like dock";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session-pre.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.plank}/bin/plank";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Cursor size configuration for COSMIC
  environment.etc."dconf/db/local.d/00-cursor-size".text = ''
    [org/gnome/desktop/interface]
    cursor-size=48
  '';
}
