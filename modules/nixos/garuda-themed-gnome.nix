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
    
    # Wallpapers and assets (manual download needed)
    # garuda-wallpapers would go here if packaged
    
    # GNOME applications and tools
    gnome-tweaks
    gnome-shell-extensions
    gnomeExtensions.dash-to-dock
    gnomeExtensions.gsconnect
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.pop-shell  # Excellent tiling window manager
    
    # Additional tools for theming
    dconf-editor          # For GTK app theming
    
    # Fonts that match Garuda's aesthetic
    jetbrains-mono
    fira-code
    noto-fonts-color-emoji
  ];

  # Enable GNOME desktop environment
  services.xserver.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  services.displayManager = {
    autoLogin = {
      enable = false;
      user = "deepwatrcreatur";
    };
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
      jetbrains-mono
      fira-code
      fira-code-symbols
    ];
    
    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrains Mono" "Fira Code" ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}

# Post-installation steps:
# 1. Icons should be available system-wide after rebuild
# 2. For wallpapers, manually download from Garuda's GitLab
# 3. Configure GNOME's theming through GNOME Tweaks
# 4. Set BeautyLine as icon theme in GNOME settings
# 5. Extract color schemes from Sweet theme for manual application