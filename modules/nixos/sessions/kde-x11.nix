# Configuration for KDE Plasma with Garuda Dragonized theming elements, forced to use X11
{
  config,
  pkgs,
  inputs,
  ...
}:

{
  # Import plasma-manager for home-manager integration
  home-manager.sharedModules = [
    inputs.plasma-manager.homeManagerModules.plasma-manager
    ../../kde-plasma.nix
  ];

  # System packages for theming
  environment.systemPackages = with pkgs; [
    # Icon themes (these work across desktop environments)
    beauty-line-icon-theme # Main Garuda icon theme
    candy-icons # Complementary icons

    # Cursor themes
    capitaine-cursors # Clean cursor theme

    # Wallpapers and assets (manual download needed)
    # garuda-wallpapers would go here if packaged

    # KDE applications and tools
    kdePackages.plasma-desktop
    kdePackages.systemsettings
    kdePackages.plasma-systemmonitor
    kdePackages.kate
    kdePackages.dolphin
    kdePackages.konsole

    # Additional tools for theming
    dconf-editor # For GTK app theming

    # Fonts that match Garuda's aesthetic
    # jetbrains-mono  # Temporarily commented out due to build issues
    fira-code
    noto-fonts-color-emoji
  ];

  # Enable KDE Plasma desktop environment
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;

  # Enable X11 for KDE
  services.xserver.enable = true;

  services.displayManager = {
    defaultSession = "plasmax11";
    autoLogin = {
      enable = true;
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
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
  };

  # Fonts configuration
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-color-emoji
      # jetbrains-mono  # Temporarily commented out due to build issues
      fira-code
      fira-code-symbols
    ];

    fontconfig = {
      defaultFonts = {
        monospace = [ "Fira Code" ]; # Removed JetBrains Mono due to build issues
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
# 3. Configure KDE's theming through System Settings
# 4. Set BeautyLine as icon theme in KDE settings
# 5. Extract color schemes from Sweet theme for manual application
