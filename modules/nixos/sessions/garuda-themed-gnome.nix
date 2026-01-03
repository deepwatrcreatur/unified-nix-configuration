# Configuration for GNOME with Garuda Dragonized theming elements
{ config, pkgs, ... }:

{
  # Enable GNOME desktop environment
  services.xserver.enable = true;
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm = {
    enable = true;
    wayland = false; # Force X11 to avoid AMD GPU issues
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = "deepwatrcreatur";
  };

  # Enable GNOME Keyring for secure credential storage (needed by Mailspring and other apps)
  services.gnome.gnome-keyring.enable = true;

  # GTK theming for applications
  programs.dconf.enable = true;

  # System packages for theming
  environment.systemPackages = with pkgs; [
    # Icon themes (these work across desktop environments)
    beauty-line-icon-theme # Main Garuda icon theme
    candy-icons # Complementary icons

    # Cursor themes
    capitaine-cursors # Clean cursor theme

    # Additional themes
    arc-theme
    adwaita-icon-theme

    # GNOME applications and tools
    gnome-tweaks
    gnome-shell-extensions

    # GNOME Extensions for macOS-like experience
    gnomeExtensions.dash-to-dock  # Floating, auto-sizing dock
    gnomeExtensions.blur-my-shell  # Transparency effects for panel and dock
    gnomeExtensions.clipboard-indicator  # Clipboard manager

    # Optional extensions (commented out for minimal setup)
    # gnomeExtensions.gsconnect
    # gnomeExtensions.pop-shell  # Tiling window manager
    # gnomeExtensions.transparent-window-moving

    # Additional tools for theming
    dconf-editor # For GTK app theming

    # Fonts that match Garuda's aesthetic
    # jetbrains-mono  # Temporarily commented out due to build issues
    fira-code
    noto-fonts-color-emoji
  ];

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
