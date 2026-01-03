{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Helper function to disable transparency for specific windows (AppImage, WhatsApp)
  disableOpacityFor = windows: [
    "100:class_g ?= '${windows}'"
  ];

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
  };

  services.displayManager = {
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
    settings = {
      # Disable opacity for AppImage and WhatsApp to prevent white windows
      opacity-rule =
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
      shadow-exclude = [
        "name = 'Notification'"
        "class_g = 'Conky'"
        "class_g ?= 'Notify-osd'"
        "class_g = 'Cairo-clock'"
        "_GTK_FRAME_EXTENTS@:c"
      ];
      transition = {
        method = "exponential-out";
        duration = 0.2;
      };
    };
  };

  # Enable sound system
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
    # Mail client with unified inbox support (Apple Mail-like)
    thunderbird # BEST unified inbox + iCloud/Gmail
    # System tray support for Thunderbird notifications
    libappindicator-gtk3
    # GNOME Keyring for secure credential storage
    libsecret
    gnome-keyring
    glib
    gsettings-desktop-schemas
  ];

  # Enable XDG portals for COSMIC
  xdg.portal = {
    enable = true;
    config.common.default = "*";
    extraPortals = with pkgs; [
      xdg-desktop-portal-cosmic
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
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

  # Plank dock service for COSMIC - macOS-like dock on the right side
  systemd.user.services.plank = lib.mkIf config.services.xserver.enable {
    description = "Plank macOS-like dock";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session-pre.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.bash}/bin/bash -c 'gsettings set net.launchpad.plank.docks:/net/launchpad/plank/docks/dock1/ alignment \"right\" && gsettings set net.launchpad.plank.docks:/net/launchpad/plank/docks/dock1/ hide-mode \"window-dodge\" && ${pkgs.plank}/bin/plank'";
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

  # Thunderbird Apple Mail-like unified inbox configuration
  environment.etc."thunderbird/prefs.js".text = ''
    /* Unified Inbox Configuration - Apple Mail Experience */

    // Enable Unified Inbox (Global Search Folder)
    user_pref("mailnews.ui.global_search_folder", "mailbox://nobody?UnifiedInbox");

    // Show unified inbox in folder pane
    user_pref("mail.ui.folderpane.show_unified_inbox", true);

    // Apple Mail-like threading and display
    user_pref("mailnews.default_view", 0); // 0 = Unified Inbox view
    user_pref("mail.thread_column", true);
    user_pref("mailnews.show_message_source", false);

    // Modern, clean interface like Apple Mail
    user_pref("mail.pane_config.dynamic", 3); // 3 = Vertical layout
    user_pref("mail.ui.show_message_preview", true);

    // Cross-account message moving
    user_pref("mail.ui.folderpane.show_toolbar", true);
    user_pref("mailnews.ui.show_folder_mode", true);

    // Smart folder behavior
    user_pref("mailnews.default_sort_order", 18); // Date descending
    user_pref("mailnews.default_sort_type", 18);    // Date

    // Apple-like conversation view
    user_pref("mailnews.show_preferred_panel", 1); // 1 = Message list panel
    user_pref("mailnews.conversation_hack", true);
  '';
}
