{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [ inputs."nix-gnome-cosmic-ui".nixosModules.default ];

  # Enable GNOME desktop environment
  # WhiteSur theming is handled by whitesur flake input in user's home-manager config
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "deepwatrcreatur";

  services.gnomeCosmicUi = {
    enable = true;
    user = "deepwatrcreatur";

    # COSMIC-like top panel
    panelOpacity = 0.15;
    panelRadius = 18;
    panelLength = -1; # shrink/dynamic
    panelAnchor = "MIDDLE";
    showTaskbar = false;

    # Workspaces
    spaceBarAlwaysShowNumbers = true;
    spaceBarShowEmptyWorkspaces = false;
    spaceBarToggleOverview = true; # click opens Overview (previews + move windows)
    spaceBarPosition = "center";

    # Dock
    dockPosition = "BOTTOM";
    dockOpacity = 0.15;
    dockIconSize = 48;

    # Tiling
    tiling = "forge";
  };

  # Make Night Light less aggressive.
  # GNOME's default here was very warm (e.g. 2700K).
  systemd.user.services.gnome-nightlight-tune = {
    description = "Tune GNOME Night Light temperature";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [
      "graphical-session.target"
      "dbus.service"
      "gnome-cosmic-ui-apply.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "gnome-nightlight-tune" ''
        set -eu
        if [ "''${USER:-}" != "deepwatrcreatur" ]; then
          exit 0
        fi

        DCONF="${pkgs.dconf}/bin/dconf"
        if ! [ -x "$DCONF" ]; then
          exit 0
        fi

        # Less warm = less aggressive.
        $DCONF write /org/gnome/settings-daemon/plugins/color/night-light-enabled true
        $DCONF write /org/gnome/settings-daemon/plugins/color/night-light-temperature "uint32 3500"
        $DCONF write /org/gnome/settings-daemon/plugins/color/night-light-schedule-automatic true
      '';
    };
  };

  # Exclude default GNOME applications we don't need
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany # GNOME web browser
    geary # Email client (using Thunderbird instead)
    gnome-music
    gnome-photos
    simple-scan
  ];

  # System packages for GNOME
  environment.systemPackages = with pkgs; [
    # GNOME essentials
    gnome-tweaks
    gnome-shell-extensions
    gnomeExtensions.appindicator

    # Audio/Volume control
    pulseaudio-ctl
    pavucontrol

    # Utilities
    flameshot # Screenshot tool
    copyq # Clipboard manager
    dconf
    dconf-editor # GUI for dconf settings

    # Mail client with unified inbox support
    thunderbird

    # System tray support
    libappindicator-gtk3

    # GNOME Keyring
    libsecret
    gnome-keyring
    glib
    gsettings-desktop-schemas
  ];

  # Touchpad configuration
  services.libinput = {
    enable = true;
    touchpad = {
      tapping = true;
      naturalScrolling = true;
      clickMethod = "clickfinger";
    };
  };

  # Disable screen lock and idle to prevent memory leaks during long idle periods
  # GNOME screensaver proxy can cause OOM crashes when locked for extended periods
  systemd.user.services."org.gnome.SettingsDaemon.ScreensaverProxy".enable = false;

  # System-level dconf overrides to disable all screen locking mechanisms.
  #
  # NOTE: Do not use `environment.etc."dconf/..."` here because `programs.dconf.enable`
  # installs `/etc/dconf` as a single immutable store path. Adding files under
  # `/etc/dconf/*` would try to create directories under that symlink and fail
  # during the `etc` derivation build.
  programs.dconf.profiles.gdm.databases = lib.mkAfter [
    {
      settings."org/gnome/desktop/screensaver" = {
        lock-enabled = false;
        lock-delay = lib.gvariant.mkUint32 0;
        idle-activation-enabled = false;
      };

      settings."org/gnome/desktop/session" = {
        idle-delay = lib.gvariant.mkUint32 0;
      };

      settings."org/gnome/settings-daemon/plugins/power" = {
        idle-dim = false;
        sleep-inactive-ac-timeout = lib.gvariant.mkInt32 0;
        sleep-inactive-battery-timeout = lib.gvariant.mkInt32 0;
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-battery-type = "nothing";
      };

      settings."org/gnome/desktop/lockdown" = {
        disable-lock-screen = true;
      };
    }
  ];

  # Enable XDG portals for GNOME
  xdg.portal = {
    enable = true;
    config.common.default = "*";
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
  };

  # GNOME Keyring daemon for credential storage
  systemd.user.services.gnome-keyring-daemon = {
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

  # Thunderbird unified inbox configuration
  environment.etc."thunderbird/prefs.js".text = ''
    /* Unified Inbox Configuration - Apple Mail Experience */

    // Enable Unified Inbox
    user_pref("mailnews.ui.global_search_folder", "mailbox://nobody?UnifiedInbox");
    user_pref("mail.ui.folderpane.show_unified_inbox", true);

    // Apple Mail-like threading and display
    user_pref("mailnews.default_view", 0);
    user_pref("mail.thread_column", true);
    user_pref("mailnews.show_message_source", false);

    // Modern, clean interface
    user_pref("mail.pane_config.dynamic", 3);
    user_pref("mail.ui.show_message_preview", true);

    // Cross-account message moving
    user_pref("mail.ui.folderpane.show_toolbar", true);
    user_pref("mailnews.ui.show_folder_mode", true);

    // Smart folder behavior
    user_pref("mailnews.default_sort_order", 18);
    user_pref("mailnews.default_sort_type", 18);

    // Apple-like conversation view
    user_pref("mailnews.show_preferred_panel", 1);
    user_pref("mailnews.conversation_hack", true);
  '';
}
