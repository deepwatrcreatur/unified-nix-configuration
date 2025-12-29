# Desktop Theming Packages Module
# Provides theme packages based on shared theming options
#
# This module installs the appropriate theme packages system-wide
# based on the desktopTheming.theme option

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.desktopTheming;

  # Theme package mapping
  themePackages = {
    whitesur = {
      gtk = pkgs.whitesur-gtk-theme;
      icons = pkgs.whitesur-icon-theme;
      cursor = pkgs.capitaine-cursors;
    };
    arc = {
      gtk = pkgs.arc-theme;
      icons = pkgs.arc-icon-theme;
      cursor = pkgs.capitaine-cursors;
    };
    adwaita = {
      gtk = pkgs.gnome-themes-extra;
      icons = pkgs.adwaita-icon-theme;
      cursor = pkgs.adwaita-icon-theme;
    };
  };

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

in {
  config = mkIf cfg.enable {
    # Install theme packages system-wide
    environment.systemPackages = mkIf (cfg.theme != "custom") [
      themePackages.${cfg.theme}.gtk
      themePackages.${cfg.theme}.icons
      themePackages.${cfg.theme}.cursor

      # Additional cursor themes
      pkgs.apple-cursor
    ];

    # Font packages
    fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-color-emoji
      fira-code
      fira-code-symbols
    ];

    # Font configuration
    fonts.fontconfig = {
      defaultFonts = {
        monospace = [ cfg.fonts.mono ];
        sansSerif = [ cfg.fonts.sans ];
        serif = [ "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };

    # Environment variables for theme detection
    environment.variables = {
      ICON_THEME = mkDefault (themePackages.${cfg.theme}.icons.pname or cfg.icons.theme);
      XCURSOR_THEME = mkDefault cfg.cursor.theme;
      XCURSOR_SIZE = mkDefault (toString cfg.cursor.size);
    };

    # Export computed theme names for use by other modules
    desktopTheming.computed = {
      gtkThemeName = themeName cfg.theme cfg.variant;
      iconThemeName = cfg.icons.theme;
      cursorThemeName = cfg.cursor.theme;
    };
  };

  # Add computed values option
  options.desktopTheming.computed = mkOption {
    type = types.attrs;
    internal = true;
    default = {};
    description = "Computed theme names for internal use";
  };
}
