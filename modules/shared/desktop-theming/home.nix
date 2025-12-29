# Desktop Theming Home Manager Module
# Provides user-level theme configuration (GTK, cursor, fonts)
#
# This module applies theme settings at the user level via Home Manager
# Works with the system-level packages module

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
  options.desktopTheming = mkOption {
    type = types.attrs;
    default = {};
    description = "Desktop theming configuration (inherited from system config when using NixOS)";
  };

  config = mkIf cfg.enable {
    # GTK theme configuration
    gtk = {
      enable = true;

      theme = {
        name = gtkThemeName;
        package = if cfg.theme == "whitesur" then pkgs.whitesur-gtk-theme
                 else if cfg.theme == "arc" then pkgs.arc-theme
                 else if cfg.theme == "adwaita" then pkgs.gnome-themes-extra
                 else null;
      };

      iconTheme = {
        name = cfg.icons.theme;
        package = if cfg.theme == "whitesur" then pkgs.whitesur-icon-theme
                 else if cfg.theme == "arc" then pkgs.arc-icon-theme
                 else if cfg.theme == "adwaita" then pkgs.adwaita-icon-theme
                 else null;
      };

      cursorTheme = {
        name = cfg.cursor.theme;
        size = cfg.cursor.size;
        package = pkgs.capitaine-cursors;
      };

      font = {
        name = cfg.fonts.sans;
        size = cfg.fonts.size;
      };

      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = cfg.variant == "dark";
      };

      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = cfg.variant == "dark";
      };
    };

    # Qt theme configuration (for Qt apps)
    qt = {
      enable = true;
      platformTheme.name = "gtk3";
      style = {
        name = "adwaita${optionalString (cfg.variant == "dark") "-dark"}";
        package = pkgs.adwaita-qt;
      };
    };

    # Home files for GTK2 apps
    home.file.".gtkrc-2.0".text = ''
      gtk-theme-name = "${gtkThemeName}"
      gtk-icon-theme-name = "${cfg.icons.theme}"
      gtk-font-name = "${cfg.fonts.sans} ${toString cfg.fonts.size}"
      gtk-cursor-theme-name = "${cfg.cursor.theme}"
      gtk-cursor-theme-size = ${toString cfg.cursor.size}
    '';

    # Session variables
    home.sessionVariables = {
      GTK_THEME = gtkThemeName;
      XCURSOR_THEME = cfg.cursor.theme;
      XCURSOR_SIZE = toString cfg.cursor.size;
    };
  };
}
