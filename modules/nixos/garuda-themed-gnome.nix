# Configuration for GNOME with Garuda Dragonized theming elements
{ config, pkgs, ... }:

{
  # System packages for theming
  environment.systemPackages = with pkgs; [
    # Icon themes (these work across desktop environments)
    beauty-line-icon-theme  # Main Garuda icon theme
    candy-icons            # Complementary icons
    
    # Cursor themes
    capitaine-cursors      # Clean cursor theme
    
    # GNOME applications and tools
    gnome-tweaks
    gnome-shell-extensions
    gnomeExtensions.dash-to-dock
    gnomeExtensions.gsconnect
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.pop-shell  # Excellent tiling window manager
    gnomeExtensions.transparent-window-moving  # For window transparency
    gnomeExtensions.blur-my-shell  # For shell transparency effects
    
    # Additional tools for theming
    dconf-editor          # For GTK app theming
    
    # Fonts that match Garuda's aesthetic
    # jetbrains-mono  # Temporarily commented out due to build issues
    fira-code
    noto-fonts-color-emoji
  ];

  # Enable GNOME desktop environment
  services.xserver.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm = {
    enable = true;
    wayland = false;  # Force X11 to avoid AMD GPU issues
  };
  services.displayManager.autoLogin = {
    enable = false;
    user = "deepwatrcreatur";
  };

  # GTK theming for applications
  programs.dconf.enable = true;
  
  # Icon theme configuration (system-wide)
  environment.variables = {
    # This may help with icon theme detection
    ICON_THEME = "BeautyLine";
  };
  
  # XDG portals for better desktop integration
  xdg.portal = {
    enable = true;
    extraPortals = [ 
      pkgs.xdg-desktop-portal-gtk 
      pkgs.xdg-desktop-portal-gnome
    ];
  };
  
  # Fonts configuration
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-emoji
      # jetbrains-mono  # Temporarily commented out due to build issues
      fira-code
      fira-code-symbols
    ];
    
    fontconfig = {
      defaultFonts = {
        monospace = [ "Fira Code" ];  # Removed JetBrains Mono due to build issues
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
