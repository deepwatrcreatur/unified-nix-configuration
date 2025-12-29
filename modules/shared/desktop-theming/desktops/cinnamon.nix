# Cinnamon Desktop Adapter for Shared Theming
# Applies shared theming options to Cinnamon-specific settings
#
# This module reads from desktopTheming.* options and applies them
# to Cinnamon's dconf settings

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

in {
  options.desktopTheming.cinnamon = {
    panels = mkOption {
      type = types.listOf types.str;
      default = [ "1:0:top" "2:0:bottom" "3:0:right" ];
      description = "Panel configuration (format: 'id:monitor:position')";
    };

    panelHeights = mkOption {
      type = types.listOf types.str;
      default = [ "1:60" "2:48" "3:64" "4:40" ];
      description = "Panel heights (format: 'id:height')";
    };

    applets = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Enabled applets configuration";
    };
  };

  config = mkIf cfg.enable {
    # Cinnamon dconf settings
    dconf.settings = {
      # Desktop Interface
      "org/cinnamon/desktop/interface" = {
        gtk-theme = gtkThemeName;
        icon-theme = cfg.icons.theme;
        cursor-theme = cfg.cursor.theme;
        cursor-size = cfg.cursor.size;
        font-name = "${cfg.fonts.sans} ${toString cfg.fonts.size}";
      };

      # Window Manager
      "org/cinnamon/desktop/wm/preferences" = {
        theme = gtkThemeName;
      };

      # Cinnamon Shell Theme
      "org/cinnamon/theme" = {
        name = gtkThemeName;
      };

      # Panel Configuration
      "org/cinnamon" = {
        panels-enabled = cfg.cinnamon.panels;
        panels-height = cfg.cinnamon.panelHeights;
        panel-autohide = false;
        panels-autohide = [ "1:false" "2:false" "3:false" "4:false" ];
        no-adjacent-panel-barriers = true;

        # Apply applets if configured
        enabled-applets = if cfg.cinnamon.applets != [] then cfg.cinnamon.applets else [
          "panel1:left:0:workspace-switcher@cinnamon.org:5"
          "panel2:right:0:systray@cinnamon.org:0"
          "panel2:right:1:notifications@cinnamon.org:1"
          "panel2:right:2:network@cinnamon.org:2"
          "panel2:right:3:sound150@claudiux:3"
          "panel2:right:4:calendar@cinnamon.org:4"
          "panel3:center:0:window-list@cinnamon.org:7"
        ];

        # Icon sizes
        panel-zone-icon-sizes = lib.hm.gvariant.mkString ''[{"panelId": 1, "left": 24, "center": 0, "right": 0}, {"panelId": 2, "left": 0, "center": 0, "right": 20}, {"panelId": 3, "left": 0, "center": ${toString cfg.dock.iconSize}, "right": 0}]'';

        # Workspace configuration
        number-of-workspaces = lib.hm.gvariant.mkInt32 1;
        workspace-names = [ "Main" ];

        # Window effects
        window-effect-close = "fade";
        window-effect-minimize = "scale";
        window-effect-unminimize = "scale";

        # Alt-Tab behavior
        alttab-switcher-style = "icons";
        alttab-switcher-show = "all-windows";

        # Hot corners
        overview-corner = true;
      };

      # Muffin (Window Manager) Settings
      "org/cinnamon/muffin" = {
        button-layout = "close,minimize,maximize:";
        focus-mode = "click";
        auto-raise = false;
        raise-on-click = true;
        edge-tiling = false;
        dynamic-workspaces = false;
        workspace-cycle = false;
      };
    };
  };
}
