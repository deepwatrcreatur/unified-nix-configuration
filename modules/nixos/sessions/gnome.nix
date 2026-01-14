{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Enable GNOME desktop environment
  # WhiteSur theming is handled by whitesur flake input in user's home-manager config
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "deepwatrcreatur";

  programs.dconf.enable = true;

  # Exclude default GNOME applications we don't need
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    epiphany # GNOME web browser
    geary # Email client (using Thunderbird instead)
    gnome-music
    gnome-photos
    simple-scan
  ];

  # System packages for GNOME with COSMIC-like features
  environment.systemPackages = with pkgs; [
    # GNOME essentials
    gnome-tweaks
    gnome-shell-extensions
    gnomeExtensions.dash-to-dock
    gnomeExtensions.appindicator
    gnomeExtensions.space-bar
    gnomeExtensions.transparent-top-bar

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

  systemd.user.services.apply-gnome-cosmic-ui = {
    description = "Apply COSMIC-like GNOME top bar and dock";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [
      "graphical-session.target"
      "dbus.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart =
        let
          script = pkgs.writeShellScript "apply-gnome-cosmic-ui" ''
            set -eu

            if [ "''${USER:-}" != "deepwatrcreatur" ]; then
              exit 0
            fi

            DCONF="${pkgs.dconf}/bin/dconf"

            if ! [ -x "$DCONF" ]; then
              exit 0
            fi

            desired_extensions="dash-to-dock@micxgx.gmail.com space-bar@luchrioh transparent-top-bar@kamens.us"

            current="$("$DCONF" read /org/gnome/shell/enabled-extensions 2>/dev/null || echo "[]")"
            normalized=$(printf '%s' "$current" | tr -d "[]'" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | sed '/^$/d' || true)

            combined=""
            for ext in $normalized; do
              combined="$combined $ext"
            done
            for ext in $desired_extensions; do
              case " $combined " in
                *" $ext "*) ;;
                *) combined="$combined $ext" ;;
              esac
            done

            out="["
            first=1
            for ext in $combined; do
              if [ $first -eq 1 ]; then
                first=0
              else
                out="$out, "
              fi
              out="$out'$ext'"
            done
            out="$out]"

            "$DCONF" write /org/gnome/shell/enabled-extensions "$out"
            "$DCONF" write /org/gnome/shell/show-applications-button "false"
            "$DCONF" write /org/gnome/shell/enable-hot-corners "false"

            "$DCONF" write /org/gnome/shell/extensions/dash-to-dock/dock-position "'LEFT'"
            "$DCONF" write /org/gnome/shell/extensions/dash-to-dock/dock-fixed "false"
            "$DCONF" write /org/gnome/shell/extensions/dash-to-dock/intellihide "true"
            "$DCONF" write /org/gnome/shell/extensions/dash-to-dock/autohide "true"
            "$DCONF" write /org/gnome/shell/extensions/dash-to-dock/autohide-in-fullscreen "true"
            "$DCONF" write /org/gnome/shell/extensions/dash-to-dock/show-apps-at-top "true"
            "$DCONF" write /org/gnome/shell/extensions/dash-to-dock/transparency-mode "'FIXED'"
            "$DCONF" write /org/gnome/shell/extensions/dash-to-dock/background-opacity "0.0"
            "$DCONF" write /org/gnome/shell/extensions/dash-to-dock/custom-theme-shrink "true"
            "$DCONF" write /org/gnome/shell/extensions/dash-to-dock/icon-size "48"
            "$DCONF" write /org/gnome/shell/extensions/dash-to-dock/dash-max-icon-size "48"

            "$DCONF" write /org/gnome/shell/extensions/transparent-top-bar/transparency "100"
          '';
        in
        "${script}";
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
