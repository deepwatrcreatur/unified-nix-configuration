{ config, pkgs, ... }:

{
  imports = [
    ../../home-manager/hyprland/default.nix
    ../whitesur-theme.nix
  ];

  # Enable the Hyprland Wayland compositor
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Enable pipewire for audio
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable display manager
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true; # Required for GDM

  # System-level packages
  environment.systemPackages = with pkgs; [
    swaylock-effects

    # Hyprland ecosystem
    hyprpaper # Wallpaper utility
    hypridle  # Idle management daemon
    hyprlock  # Screen locker
    xdg-desktop-portal-hyprland
    waybar # Status bar
    wofi   # Application launcher
    
    # Utilities
    pavucontrol # Volume control
    networkmanagerapplet # Network manager applet
    brightnessctl
    wl-clipboard # Clipboard tool for wayland
    
    # Themeing
    libsForQt5.qt5ct
    
    # Fonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    
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
    noto-fonts-cjk
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
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
