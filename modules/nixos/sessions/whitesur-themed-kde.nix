{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  # KDE Plasma with WhiteSur theming for workstation
  # Similar aesthetic to COSMIC but with KDE's power and Thunderbird badge support

  # Import plasma-manager for home-manager integration
  home-manager.sharedModules = [
    inputs.plasma-manager.homeModules.plasma-manager
    ../../kde-plasma.nix
  ];

  # Enable KDE Plasma 6 desktop environment
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;

  # Enable X11 for KDE (Wayland support can be added later if desired)
  services.xserver.enable = true;

  services.displayManager = {
    defaultSession = "plasmax11";
    autoLogin = {
      enable = true;
      user = "deepwatrcreatur";
    };
  };

  # System packages for KDE and theming
  environment.systemPackages = with pkgs; [
    # KDE core applications
    kdePackages.plasma-desktop
    kdePackages.systemsettings
    kdePackages.plasma-systemmonitor
    kdePackages.kate
    kdePackages.dolphin
    kdePackages.konsole

    # QML modules for KDE plasmoids (fixes missing module errors)
    kdePackages.bluedevil
    kdePackages.plasma-bluetooth

    # Utilities
    dconf-editor # For GTK app theme configuration
    libsecret
    gnome-keyring # For credential storage (works cross-DE)

    # Thunderbird and mail support
    thunderbird
    libappindicator-gtk3

    # Fonts
    noto-fonts
    noto-fonts-color-emoji
    fira-code
    fira-code-symbols
  ];

  # GTK theming for non-KDE applications
  programs.dconf.enable = true;

  # WhiteSur theming configuration
  environment.variables = {
    ICON_THEME = "WhiteSur";
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
      fira-code
      fira-code-symbols
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

}
