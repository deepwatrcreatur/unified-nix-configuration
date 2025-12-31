{ config, pkgs, lib, ... }:

{
  # ===========================================
  # WhiteSur Theme System Configuration
  # ===========================================
  # Provides macOS-like theming for desktop environments
  # Includes GTK themes, icons, cursors, and fonts

  # ===========================================
  # System Packages for WhiteSur Theming
  # ===========================================
  environment.systemPackages = with pkgs; [
    # WhiteSur theme packages
    whitesur-gtk-theme
    whitesur-icon-theme
    
    # Cursor theme
    capitaine-cursors
    
    # Font packages for macOS-like appearance
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    
    # Plank dock for macOS-like dock experience
    plank
  ];

  # ===========================================
  # Font Configuration
  # ===========================================
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ];
    
    fontconfig = {
      defaultFonts = {
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
        monospace = [ "Noto Sans Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # ===========================================
  # GTK Theme Configuration (System-wide fallback)
  # ===========================================

  environment.etc."gtk-3.0/settings.ini".text = lib.mkDefault (lib.mkAfter ''
    [Settings]
    gtk-theme-name = WhiteSur-Dark
    gtk-icon-theme-name = WhiteSur
    gtk-cursor-theme-name = capitaine-cursors
    gtk-font-name = Noto Sans 11
    gtk-application-prefer-dark-theme = true
  '');

  environment.etc."gtk-4.0/settings.ini".text = lib.mkDefault (lib.mkAfter ''
    [Settings]
    gtk-theme-name = WhiteSur-Dark
    gtk-icon-theme-name = WhiteSur
    gtk-cursor-theme-name = capitaine-cursors
    gtk-font-name = Noto Sans 11
    gtk-application-prefer-dark-theme = true
  '');

  # ===========================================
  # Cursor Theme Configuration
  # ===========================================

  environment.etc."icons/default/index.theme".text = lib.mkDefault (lib.mkAfter ''
    [Icon Theme]
    Name=Capitaine Cursors
    Inherits=capitaine-cursors
  '');

  # ===========================================
  # Environment Variables
  # ===========================================
  # GTK theme settings
  environment.variables = {
    GTK_THEME = "WhiteSur-Dark";
    GTK_ICON_THEME = "WhiteSur";
    GTK_CURSOR_THEME = "capitaine-cursors";
  };

  # ===========================================
  # Autostart Configuration for Plank Dock
  # ===========================================
  # Create autostart entry for Plank (macOS-like dock)
  environment.etc."xdg/autostart/plank.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Plank
    Comment=MacOS-style dock for Linux
    Exec=plank
    Terminal=false
    StartupNotify=false
  '';
}