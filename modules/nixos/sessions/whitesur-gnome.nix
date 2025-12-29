# Configuration for GNOME with WhiteSur macOS-like theming
{ config, pkgs, ... }:

{
  # Enable GNOME desktop environment
  services.xserver.enable = true;
  services.desktopManager.gnome.enable = true;
  
  # Configure autorepeat for Proxmox guest to prevent stuck keypresses
  services.xserver.autoRepeatDelay = 300;
  services.xserver.autoRepeatInterval = 40;
  
  services.displayManager.gdm = {
    enable = true;
    wayland = true; # GNOME 49+ requires Wayland (no X11 session available)
    # NOTE: If you need X11 for deskflow, you may need to use XWayland compatibility
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = "deepwatrcreatur";
  };
  services.displayManager.defaultSession = "gnome";

  # Import shared WhiteSur theming
  imports = [
    ./whitesur-theme.nix
  ];

  # GNOME-specific packages
  environment.systemPackages = with pkgs; [
    # GNOME applications and tools
    gnome-tweaks
    gnome-shell-extensions
    deskflow
    gnomeExtensions.dash-to-dock
    gnomeExtensions.clipboard-indicator
    gnomeExtensions.blur-my-shell  # For shell transparency effects
    # gnomeExtensions.gsconnect
    # gnomeExtensions.pop-shell  # Excellent tiling window manager
    # gnomeExtensions.transparent-window-moving  # For window transparency
    # gnomeExtensions.weather-oclock

    # Additional tools for theming
    dconf-editor # For GTK app theming
  ];

  # Enable dconf for theme configuration
  programs.dconf.enable = true;

  # Theme configuration is handled by Home Manager
  # See: modules/home-manager/gnome-whitesur.nix
  # This provides declarative dconf settings for WhiteSur theme

  # XDG portals for better desktop integration
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
  };

  # Touchpad Configuration for macOS-like Gestures
  services.libinput = {
    enable = true;
    touchpad = {
      tapping = true;
      naturalScrolling = true;  # macOS-like scrolling
      clickMethod = "clickfinger";
    };
  };
}
