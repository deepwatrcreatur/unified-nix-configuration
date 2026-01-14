{ config, pkgs, ... }:

{
  imports = [
    ../whitesur-theme.nix
  ];

  # Enable the Hyprland Wayland compositor
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Enable display manager
  services.displayManager.gdm.enable = false;
  services.desktopManager.gnome.enable = false;

  # System-level packages
  environment.systemPackages = with pkgs; [
    swaylock-effects

    # Hyprland ecosystem
    hyprpaper # Wallpaper utility
    hypridle # Idle management daemon
    hyprlock # Screen locker
    xdg-desktop-portal-hyprland # Required for screensharing/casting
    waybar # Status bar
    wofi # Application launcher

    # Utilities
    pavucontrol # Volume control
    networkmanagerapplet # Network manager applet
    brightnessctl
    wl-clipboard # Clipboard tool for wayland

    # Themeing
    libsForQt5.qt5ct

    # Fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji

    # Apps from cosmic.nix
    pulseaudio-ctl
    flameshot
    copyq
    dconf
    gnome-shell-extensions
    thunderbird
    libappindicator-gtk3
    libsecret
    gnome-keyring
    glib
    gsettings-desktop-schemas
  ];

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];

  # Configure environment variables
  environment.variables = {
    XCURSOR_SIZE = "24";
    QT_QPA_PLATFORMTHEME = "qt5ct";
  };

  # XDG Portals
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  # Disable auto-suspend
  # services.logind.idleAction = "ignore"; # Temporarily commented out to fix build error
}
