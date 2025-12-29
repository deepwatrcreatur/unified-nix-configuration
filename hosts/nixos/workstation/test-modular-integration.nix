# Test integration of modular theming system
# This module can be imported into default.nix to test the modular system
# without disrupting the existing working configuration

{ config, lib, pkgs, ... }:

{
  imports = [
    ../../../modules/shared/desktop-theming
    ../../../modules/shared/desktop-theming/packages.nix
  ];

  # Configure theming options
  desktopTheming = {
    enable = true;
    theme = "whitesur";
    variant = "dark";

    cursor = {
      theme = "capitaine-cursors";
      size = 48;
    };

    icons.theme = "WhiteSur";

    fonts = {
      sans = "Noto Sans";
      mono = "Fira Code";
      size = 11;
    };

    dock = {
      position = "right";
      alignment = "center";
      iconSize = 48;
      transparency = 0.3;
    };

    panel = {
      height = 60;
      transparency = 0.3;
    };

    # Cinnamon-specific settings
    cinnamon = {
      panels = [ "1:0:top" "2:0:bottom" "3:0:right" ];
      panelHeights = [ "1:60" "2:48" "3:64" "4:40" ];
    };
  };
}
