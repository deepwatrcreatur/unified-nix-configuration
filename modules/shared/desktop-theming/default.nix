# Shared Desktop Theming Module
# Provides common theming options and packages for macOS-like desktop environments
#
# This module can be used across different desktop environments (GNOME, Cinnamon, XFCE, etc.)
# and provides a consistent interface for theming configuration.

{ config, lib, pkgs, ... }:

with lib;

{
  options.desktopTheming = {
    enable = mkEnableOption "desktop theming with macOS-like appearance";

    theme = mkOption {
      type = types.enum [ "whitesur" "arc" "adwaita" "custom" ];
      default = "whitesur";
      description = "Theme to use for desktop theming";
    };

    variant = mkOption {
      type = types.enum [ "light" "dark" ];
      default = "dark";
      description = "Theme variant (light or dark)";
    };

    cursor = {
      theme = mkOption {
        type = types.str;
        default = "capitaine-cursors";
        description = "Cursor theme name";
      };

      size = mkOption {
        type = types.int;
        default = 48;
        description = "Cursor size in pixels";
      };
    };

    icons = {
      theme = mkOption {
        type = types.str;
        default = "WhiteSur";
        description = "Icon theme name";
      };
    };

    fonts = {
      sans = mkOption {
        type = types.str;
        default = "Noto Sans";
        description = "Sans-serif font family";
      };

      mono = mkOption {
        type = types.str;
        default = "Fira Code";
        description = "Monospace font family";
      };

      size = mkOption {
        type = types.int;
        default = 11;
        description = "Default font size";
      };
    };

    dock = {
      position = mkOption {
        type = types.enum [ "left" "right" "top" "bottom" ];
        default = "right";
        description = "Dock position on screen";
      };

      alignment = mkOption {
        type = types.enum [ "start" "center" "end" ];
        default = "center";
        description = "Dock alignment within its edge";
      };

      iconSize = mkOption {
        type = types.int;
        default = 48;
        description = "Dock icon size in pixels";
      };

      transparency = mkOption {
        type = types.float;
        default = 0.3;
        description = "Dock transparency (0.0 to 1.0, lower is more transparent)";
      };
    };

    panel = {
      height = mkOption {
        type = types.int;
        default = 48;
        description = "Panel height in pixels";
      };

      transparency = mkOption {
        type = types.float;
        default = 0.3;
        description = "Panel transparency (0.0 to 1.0, lower is more transparent)";
      };
    };

    # Desktop-specific options (declared here, used by desktop adapters)
    cinnamon = mkOption {
      type = types.attrs;
      default = {};
      description = "Cinnamon-specific options (defined in desktops/cinnamon.nix)";
    };

    gnome = mkOption {
      type = types.attrs;
      default = {};
      description = "GNOME-specific options (defined in desktops/gnome.nix)";
    };
  };

  config = mkIf config.desktopTheming.enable {
    # This is a shared module - actual implementation is in
    # desktop-specific modules (cinnamon, gnome, etc.)
    # They will read these options and apply them appropriately
  };
}
