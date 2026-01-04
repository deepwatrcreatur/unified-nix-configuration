{ config, pkgs, ... }:

{
  # COSMIC Desktop Environment - Home Manager dconf settings
  # Handles appearance, keybindings, dock configuration, and behavior
  # System-level setup is in modules/nixos/sessions/cosmic.nix

  dconf.settings = {
    # GNOME/COSMIC shell extension configuration
    "org/gnome/shell" = {
      enabled-extensions = [
        "dash-to-dock@micxgx.gmail.com"
      ];
      # Top bar styling for macOS-like appearance
      "show-applications-button" = false;
      "enable-hot-corners" = false;
    };

    # Dash-to-dock configuration for macOS-like right-aligned dock with enhanced styling
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "RIGHT";
      dock-fixed = false;
      intellihide = true;
      autohide = true;
      autohide-in-fullscreen = true;
      show-apps-at-top = true;
      # Enhanced transparency for glossy appearance
      transparency-mode = "DYNAMIC";
      background-opacity = 0.15;
      icon-size-fixed = false;
      max-alpha = 0.95;
      min-alpha = 0.15;
      # Better spacing and sizing for macOS-like feel
      icon-size = 48;
      dash-max-icon-size = 48;
      scroll-action = "cycle-windows";
      shift-click-action = "minimize";
      middle-click-action = "launch";
      # Dock styling
      custom-theme-shrink = true;
      disable-overview-on-startup = false;
    };

    # COSMIC visual appearance - macOS-like dark theme
    "org/gnome/desktop/interface" = {
      gtk-application-prefer-dark-style = true;
      color-scheme = "prefer-dark";
      # Cursor size (fonts and cursor-theme are set by whitesur module)
      cursor-size = 45;
    };

    # Window decoration - macOS-style button layout (right side, minimize-maximize-close order)
    "org/gnome/desktop/wm/preferences" = {
      button-layout = ":close,minimize,maximize";
      focus-mode = "sloppy";
      # Window appearance
      action-middle-click-titlebar = "toggle-maximize";
      action-right-click-titlebar = "menu";
      # Double-click title bar behavior (like macOS)
      action-double-click-titlebar = "maximize";
    };

    # Custom keybindings for rofi launcher
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi-drun/"
      ];
    };

    # Rofi application launcher keybinding (Cmd/Super + Space = launcher)
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi-drun" = {
      binding = "<Super>space";
      command = "${pkgs.rofi}/bin/rofi -show drun";
      name = "Launch Application (rofi drun)";
    };

    # Screen lock and idle configuration
    "org/gnome/desktop/screensaver" = {
      lock-enabled = false;
    };

    "org/gnome/desktop/lockdown" = {
      disable-lock-screen = true;
    };

    "org/gnome/desktop/session" = {
      idle-delay = 600; # 10 minutes
    };

    # Power management - dims after 2 minutes, no sleep
    "org/gnome/settings-daemon/plugins/power" = {
      idle-dim-timeout = 120;
      sleep-inactive-ac-timeout = 3600; # 1 hour screen off
      sleep-inactive-ac-type = "blank";
    };

    # GTK settings for smooth appearance
    "org/gtk/settings/file-chooser" = {
      sort-directories-first = true;
    };
  };
}
