# Configuration for GNOME with WhiteSur macOS-like theming
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

  # Import shared WhiteSur theming
  imports = [
    ./whitesur-theme.nix
  ];

  # GNOME-specific packages
  environment.systemPackages = with pkgs; [
    # GNOME applications and tools
    gnome-tweaks
    gnome-shell-extensions
    # gnomeExtensions.dash-to-dock
    # gnomeExtensions.gsconnect
    # gnomeExtensions.clipboard-indicator
    # gnomeExtensions.pop-shell  # Excellent tiling window manager
    # gnomeExtensions.transparent-window-moving  # For window transparency
    # gnomeExtensions.blur-my-shell  # For shell transparency effects
    # gnomeExtensions.weather-oclock

    # Additional tools for theming
    dconf-editor # For GTK app theming
  ];

  # Apply WhiteSur themes via dconf for GNOME
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface" = {
        gtk-theme = "WhiteSur-dark";
        icon-theme = "WhiteSur";
        cursor-theme = "White-cursor";
        font-name = "Noto Sans 11";
        document-font-name = "Noto Sans 11";
        monospace-font-name = "Fira Code 11";
      };
      settings."org/gnome/desktop/wm/preferences" = {
        theme = "WhiteSur-dark";
      };
    }
  ];

  # XDG portals for better desktop integration
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
  };
}
