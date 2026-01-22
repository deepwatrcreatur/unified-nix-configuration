{
  config,
  lib,
  pkgs,
  ...
}:

let
  # COSMIC sessions launched via greetd can start very early in boot.
  # On some hardware that means the compositor comes up before DRM exposes
  # outputs, leading to "Backend initialized without output" and a black screen.
  #
  # Wait briefly for DRM connectors, then launch COSMIC under a fresh D-Bus
  # session bus.
  cosmicSessionCommand = pkgs.writeShellScript "cosmic-session-greetd" ''
    set -eu

    # Wait up to ~10s for a connected DRM output.
    for _ in $(seq 1 50); do
      if ls /sys/class/drm/card*-*/status >/dev/null 2>&1 \
        && rg -q "^connected$" /sys/class/drm/card*-*/status 2>/dev/null; then
        break
      fi
      sleep 0.2
    done

    exec ${pkgs.dbus}/bin/dbus-run-session ${pkgs.cosmic-session}/bin/cosmic-session
  '';

  # Text-mode greeter that always works on a VT. This is intentionally boring
  # but extremely reliable as a recovery path.
  tuiGreeterCommand = pkgs.writeShellScript "tuigreet-greeter" ''
    set -eu
    exec ${pkgs.tuigreet}/bin/tuigreet \
      --time \
      --remember \
      --cmd ${lib.escapeShellArg (toString cosmicSessionCommand)}
  '';
in
{
  # Enable COSMIC desktop environment with native Wayland support
  services.desktopManager.cosmic.enable = true;

  # COSMIC is a native Wayland session. Prefer keeping X11 off, but do not use
  # mkForce so specialisations (e.g. GNOME fallback) can override cleanly.
  services.xserver.enable = lib.mkDefault false;
  services.xserver.displayManager.lightdm.enable = lib.mkDefault false;
  services.displayManager.gdm.enable = lib.mkDefault false;
  services.displayManager.sddm.enable = lib.mkDefault false;

  # Avoid the historic COSMIC greeter memory leak by not using it.
  # Use greetd and launch COSMIC as the session.
  #
  # NOTE: COSMIC packages (including cosmic-session) are still coming from your
  # nixpkgs-unstable overlay in `flake.nix`.
  services.displayManager.cosmic-greeter.enable = lib.mkForce false;

  services.greetd = {
    enable = true;
    settings = {
      # Auto-login into COSMIC.
      # If the session exits, greetd will fall back to the greeter.
      initial_session = {
        command = lib.mkForce (toString cosmicSessionCommand);
        user = lib.mkForce "deepwatrcreatur";
      };

      # Keep a greeter available for recovery.
      default_session = {
        command = lib.mkForce (toString tuiGreeterCommand);
        user = lib.mkForce "greeter";
      };
    };
  };

  # Ensure the greetd user exists.
  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
    extraGroups = [
      "video"
      "input"
    ];
  };
  users.groups.greeter = { };

  # Disable screen locking / idle-triggered lock.
  # COSMIC's lock/idle implementation is still evolving; these overrides are
  # intentionally defensive.
  services.logind.settings.Login = {
    IdleAction = "ignore";
    IdleActionSec = 0;
  };

  systemd.user.services.cosmic-idle.enable = lib.mkForce false;
  systemd.user.services.cosmic-lock.enable = lib.mkForce false;

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
    pulseaudio-ctl
    pavucontrol
    flameshot
    copyq

    # Needed for COSMIC settings and schema availability.
    dconf
    glib
    gsettings-desktop-schemas

    # Greeters. `tuigreet` is used for a reliable recovery login.
    tuigreet
    gtkgreet

    # COSMIC sessions started from greetd benefit from a known dbus-run-session.
    dbus

    gnome-shell-extensions # For dash-to-dock extension
    # Mail client with unified inbox support (Apple Mail-like)
    thunderbird # BEST unified inbox + iCloud/Gmail
    # System tray support for Thunderbird notifications
    libappindicator-gtk3
    # GNOME Keyring for secure credential storage
    libsecret
    gnome-keyring
  ];

  # COSMIC uses gsettings/dconf; without this you get "No schemas installed".
  programs.dconf.enable = true;

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

  # Desktop appearance, keybindings, and idle settings are now configured declaratively
  # via home-manager dconf in modules/home-manager/cosmic-settings.nix
  # This approach avoids timing issues and greeter conflicts with systemd services

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

  # Note: Keyboard keybindings are configured via home-manager dconf settings
  # in modules/home-manager/cosmic-settings.nix using the standard GNOME keybindings schema

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
