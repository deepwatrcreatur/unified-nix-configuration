{ config, pkgs, lib, ... }:

{
  # ===========================================
  # macOS-like Theming with WhiteSur
  # ===========================================
  # This module provides macOS-like theming for GTK-based desktop environments
  # Supports: GNOME, Cinnamon, XFCE, MATE, LXDE

  # Enable dconf for theme configuration
  programs.dconf.enable = true;

  # ===========================================
  # Font Configuration
  # ===========================================

  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-color-emoji
      fira-code
    ];

    fontconfig = {
      defaultFonts = {
        monospace = [ "Fira Code" ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # ===========================================
  # System Packages for macOS-like Appearance
  # ===========================================

  environment.systemPackages = with pkgs; [
    # WhiteSur macOS-like GTK theme
    whitesur-gtk-theme

    # WhiteSur macOS-like icon theme
    whitesur-icon-theme

    # Apple cursor theme (macOS-like)
    apple-cursor

    # Alternative cursor themes
    capitaine-cursors

    # Plank - macOS-like dock
    plank

    # Additional themes that work well with macOS styling
    arc-theme
    adwaita-icon-theme
  ];

  # ===========================================
  # Environment Variables for Theme Detection
  # ===========================================

  environment.variables = {
    # Help with icon theme detection
    ICON_THEME = "WhiteSur";

    # Cursor theme
    XCURSOR_THEME = "White-cursor";
    XCURSOR_SIZE = "24";
  };

  # ===========================================
  # Plank Dock Configuration
  # ===========================================
  # NOTE: Plank service is now managed by Home Manager
  # See: modules/home-manager/cinnamon.nix (or other DE modules)
  # This provides declarative configuration of dock position, theme, etc.

  # ===========================================
  # Theme Configuration (via dconf)
  # ===========================================
  # Individual desktop environments should apply their own theme settings
  # This module provides the base packages and configuration
}
