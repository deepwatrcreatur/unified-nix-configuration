{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Helper function to disable transparency for specific windows (AppImage, WhatsApp)
  disableOpacityFor = windows: {
    opacityRule = [
      "100:class_g ?= '${windows}'"
    ];
  };

in
{
  # Enable X11 with Xwayland support and use available GPUs
  services.xserver = {
    enable = true;
    videoDrivers = [
      "amdgpu"
      "nvidia"
    ];
    xrandrHeads = [
      {
        output = "DP-1";
        monitorConfig = ''
          Option "Position" "0 0"
          Option "Enable" "true"
        '';
      }
      {
        output = "HDMI-A-1";
        monitorConfig = ''
          Option "Position" "2560 0"
          Option "Enable" "true"
        '';
      }
    ];
    displayManager = {
      sddm = {
        enable = true;
        theme = "WhiteSur";
        settings = {
          Theme = {
            Current = "WhiteSur";
            CursorTheme = "WhiteSur-cursors";
            Font = "JetBrainsMono Nerd Font 10";
            Face = "${config.users.users.deepwatrcreatur.home}/.face";
          };
        };
      };
    };
    windowManager = {
      picom = {
        enable = true;
        fade = true;
        fadeDelta = 5;
        fadeSteps = [
          0.01
          0.0125
        ];
        shadow = true;
        shadowOffsets = [
          (-15)
          (-15)
        ];
        shadowOpacity = 0.25;
        backend = "glx";
        vSync = true;
        settings = {
          # Disable opacity for AppImage and WhatsApp to prevent white windows
          opacityRules =
            (disableOpacityFor "appimage")
            ++ (disableOpacityFor "whatsapp")
            ++ [
              "100:class_g ?= 'Gimp'"
              "100:class_g ?= 'Google-chrome'"
              "100:class_g ?= 'firefox'"
              "100:class_g ?= 'TelegramDesktop'"
              "100:name ?= 'screenshot'"
              "100:name ?= 'rofi'"
              "100:name ?= 'dmenu'"
              "100:name ?= 'figma'"
              "100:name ?= 'maim'"
              "100:name ?= ' Flameshot'"
              "100:class_g ?= 'Pavucontrol'"
              "100:class_g ?= 'copyq'"
            ];
          corner-radius = 12;
          blur = {
            method = "gaussian";
            size = 5;
            deviation = 3.0;
          };
          shadow = {
            offset = -15;
            opacity = 0.25;
            ignore-shaped = true;
            blur-strength = 5;
          };
          transition = {
            method = "exponential-out";
            duration = 0.2;
          };
        };
      };
    };
  };

  # Enable sound system
  hardware.pulseaudio.enable = true;

  # Enable GNOME Keyring for secure credential storage (needed by Mailspring and other apps)
  services.gnome.gnome-keyring.enable = true;

  # Compositor for macOS-like transparency effects
  services.picom = {
    enable = true;
    fade = true;
    fadeDelta = 5;
    fadeSteps = [
      0.01
      0.0125
    ];
    shadow = true;
    shadowOffsets = [
      (-15)
      (-15)
    ];
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
    # Thunderbird for unified inbox with iCloud + Gmail
    thunderbird
    # Mailspring dependencies for secure credential storage
    libsecret
    gnome-keyring
    glib
    gsettings-desktop-schemas
  ];

  # Enable XDG portals for COSMIC
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-cosmic
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
  };

  # Auto-start COSMIC panel and dock
  systemd.user.services.cosmic-panel = lib.mkIf config.services.xserver.enable {
    description = "COSMIC panel for desktop management";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.deskflow}/bin/cosmic-panel";
      Restart = "on-failure";
      RestartSec = 5;
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
      RestartSec = 5;
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

  # COSMIC idle configuration service - ensures proper screen timing settings
  systemd.user.services.cosmic-idle-config = lib.mkIf config.services.xserver.enable {
    description = "Configure COSMIC idle settings: 2min dim, 10min screensaver, 60min screen off, no lock";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 3 && gsettings set org.gnome.desktop.screensaver lock-enabled false && gsettings set org.gnome.desktop.session idle-delay 600 && gsettings set org.gnome.desktop.lockdown disable-lock-screen true && gsettings set org.gnome.settings-daemon.plugins.power idle-dim-timeout 120 && gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 3600 || true'";
      RemainAfterExit = true;
    };
  };

  # GNOME Keyring daemon for Mailspring secure credential storage
  systemd.user.services.gnome-keyring-daemon = lib.mkIf config.services.xserver.enable {
    description = "GNOME Keyring daemon for secure credential storage";
    wantedBy = [ "graphical-session.target" ];
    after = [ "dbus.service" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = "GNOME_KEYRING_CONTROL=/run/user/%u/keyring/control";
    };
  };

  # Cursor size configuration for COSMIC
  environment.etc."dconf/db/local.d/00-cursor-size".text = ''
    [org/gnome/desktop/interface]
    cursor-size=48
  '';

  # Disable lock screen with custom timing: 2min dim, 10min screensaver, 60min screen off
  environment.etc."dconf/db/local.d/00-cosmic-screen-settings".text = ''
    [org/gnome/desktop/screensaver]
    lock-enabled=false
    lock-delay=uint32 0
    ubuntu-lock-on-suspend=false

    [org/gnome/desktop/session]
    idle-delay=uint32 600

    [org/gnome/settings-daemon/plugins/power]
    sleep-inactive-ac-timeout=uint32 3600
    sleep-inactive-battery-timeout=uint32 3600
    idle-dim-timeout=uint32 120

    [org/gnome/desktop/lockdown]
    disable-lock-screen=true
  '';
}
