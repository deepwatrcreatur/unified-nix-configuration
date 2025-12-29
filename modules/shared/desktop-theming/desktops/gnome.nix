# GNOME Desktop Adapter for Shared Theming
# Applies shared theming options to GNOME-specific settings
#
# This module reads from desktopTheming.* options and applies them
# to GNOME's dconf settings and Dash-to-Dock extension

{ config, lib, pkgs, osConfig ? {}, ... }:

with lib;

let
  # Use osConfig if available (NixOS), otherwise use config
  themingConfig = osConfig.desktopTheming or config.desktopTheming;
  cfg = themingConfig;

  # Get theme name with variant
  themeName = theme: variant:
    if theme == "whitesur" then
      "WhiteSur-${if variant == "dark" then "Dark" else "Light"}"
    else if theme == "arc" then
      "Arc-${if variant == "dark" then "Dark" else ""}"
    else if theme == "adwaita" then
      if variant == "dark" then "Adwaita-dark" else "Adwaita"
    else
      theme;

  gtkThemeName = themeName cfg.theme cfg.variant;

  # Map our dock position to GNOME's format
  dockPosition = {
    left = "LEFT";
    right = "RIGHT";
    top = "TOP";
    bottom = "BOTTOM";
  }.${cfg.dock.position};

  # Map alignment to GNOME's format
  dockAlignment = {
    start = "START";
    center = "CENTER";
    end = "END";
  }.${cfg.dock.alignment};

in {
  options.desktopTheming.gnome = {
    extensions = mkOption {
      type = types.listOf types.str;
      default = [
        "dash-to-dock@micxgx.gmail.com"
        "blur-my-shell@aunetx"
        "clipboard-indicator@tudmotu.com"
      ];
      description = "Enabled GNOME extensions";
    };
  };

  config = mkIf cfg.enable {
    # GNOME dconf settings
    dconf.settings = {
      # Desktop Interface
      "org/gnome/desktop/interface" = {
        color-scheme = if cfg.variant == "dark" then "prefer-dark" else "prefer-light";
        gtk-theme = gtkThemeName;
        icon-theme = cfg.icons.theme;
        cursor-theme = cfg.cursor.theme;
        cursor-size = cfg.cursor.size;
        font-name = "${cfg.fonts.sans} ${toString cfg.fonts.size}";
        enable-animations = true;
      };

      # Window Manager
      "org/gnome/desktop/wm/preferences" = {
        button-layout = "close,minimize,maximize:";  # macOS-style
        focus-mode = "click";
        resize-with-right-button = true;
        num-workspaces = 1;
        theme = gtkThemeName;
        workspace-names = [ "Main" ];
      };

      # Mutter (Window Manager)
      "org/gnome/mutter" = {
        dynamic-workspaces = false;
        workspaces-only-on-primary = true;
      };

      # GNOME Shell Extensions
      "org/gnome/shell" = {
        enabled-extensions = cfg.gnome.extensions;
      };

      # Dash to Dock Configuration
      "org/gnome/shell/extensions/dash-to-dock" = {
        # Position and size
        dock-position = dockPosition;
        dock-fixed = false;  # Floating dock
        extend-height = false;  # Don't extend to full height
        dock-alignment = dockAlignment;

        # Auto-hide behavior
        autohide = false;  # Always visible with transparency
        intellihide = false;

        # Transparency
        transparency-mode = "DYNAMIC";
        background-opacity = cfg.dock.transparency;
        customize-alphas = true;
        min-alpha = cfg.dock.transparency - 0.1;
        max-alpha = cfg.dock.transparency + 0.5;

        # Icon configuration
        icon-size-fixed = true;
        dash-max-icon-size = cfg.dock.iconSize;
        show-apps-at-top = false;

        # Behavior
        click-action = "minimize-or-previews";  # macOS-like
        scroll-action = "cycle-windows";

        # Appearance
        apply-custom-theme = true;
        custom-theme-shrink = false;
        running-indicator-style = "DOTS";  # macOS style
      };

      # Blur My Shell Extension
      "org/gnome/shell/extensions/blur-my-shell/panel" = {
        blur = true;
        brightness = 0.8;
        sigma = 15;
        static-blur = true;
        unblur-in-overview = false;
      };

      "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
        blur = true;
        brightness = 0.7;
        sigma = 15;
        static-blur = true;
        unblur-in-overview = false;
      };

      "org/gnome/shell/extensions/blur-my-shell/applications" = {
        blur = false;
      };

      # Desktop Background
      "org/gnome/desktop/background" = {
        picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/nature.jpg";
        picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/nature.jpg";
        picture-options = "zoom";
      };

      # Screen Lock and Session
      "org/gnome/desktop/screensaver" = {
        lock-enabled = false;
        idle-activation-enabled = false;
      };

      "org/gnome/desktop/session" = {
        idle-delay = lib.hm.gvariant.mkUint32 0;
      };

      "org/gnome/settings-daemon/plugins/power" = {
        sleep-inactive-ac-type = "nothing";
        sleep-inactive-battery-type = "nothing";
      };
    };

    # GNOME Keyring
    services.gnome-keyring = {
      enable = true;
      components = [ "pkcs11" "secrets" ];
    };
  };
}
