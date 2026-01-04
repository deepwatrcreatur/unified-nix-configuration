{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Enable COSMIC desktop environment with native Wayland support
  services.desktopManager.cosmic.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # Touchpad configuration
  services.libinput = {
    enable = true;
    touchpad = {
      tapping = true;
      naturalScrolling = true;
      clickMethod = "clickfinger";
    };
  };

  # System packages for COSMIC
  environment.systemPackages = with pkgs; [
    deskflow
    pulseaudio-ctl
    pavucontrol
    flameshot
    copyq
    dconf
    gnome-shell-extensions # For dash-to-dock extension
    rofi # Application launcher
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

  # Configure dash-to-dock extension for COSMIC (right-aligned dock)
  systemd.user.services.cosmic-dock-config = {
    description = "Configure dash-to-dock for macOS-like appearance on right side";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 2 && gsettings set org.gnome.shell.extensions.dash-to-dock dock-position \"right\" && gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false || true'";
      RemainAfterExit = true;
    };
  };

  # Configure visual appearance - transparent top bar, shadows, rounded corners
  systemd.user.services.cosmic-visual-config = {
    description = "Configure COSMIC visual appearance with macOS-like styling";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 3 && gsettings set org.gnome.desktop.interface gtk-application-prefer-dark-style true && gsettings set org.gnome.desktop.wm.preferences button-layout \":close,minimize,maximize\" || true'";
      RemainAfterExit = true;
    };
  };

  # Configure rofi launcher with Space bar keybinding
  systemd.user.services.rofi-keybinding = {
    description = "Configure rofi launcher with Space bar keybinding";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 3 && gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \"['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi/']\" && gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi/ name \"Launch rofi\" && gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi/ command \"${pkgs.rofi}/bin/rofi -show drun\" && gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybindings:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi/ binding \"space\" || true'";
      RemainAfterExit = true;
    };
  };

  # COSMIC idle configuration service - ensures no lock screen
  systemd.user.services.cosmic-idle-config = {
    description = "Configure COSMIC idle settings: 2min dim, 10min screensaver, 60min screen off, no lock";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 3 && gsettings set org.gnome.desktop.screensaver lock-enabled false && gsettings set org.gnome.desktop.session idle-delay 600 && gsettings set org.gnome.desktop.lockdown disable-lock-screen true && gsettings set org.gnome.settings-daemon.plugins.power idle-dim-timeout 120 && gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 3600 || true'";
      RemainAfterExit = true;
    };
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
