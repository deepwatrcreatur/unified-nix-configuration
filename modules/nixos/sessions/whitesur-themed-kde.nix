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
    inputs.plasma-manager.homeManagerModules.plasma-manager
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

    # Theming
    whitesur-icon-theme
    whitesur-cursor-theme

    # Utilities
    dconf-editor # For GTK app theme configuration
    libsecret
    gnome-keyring # For credential storage (works cross-DE)

    # Thunderbird and mail support
    thunderbird
    libappindicator-gtk3

    # XDG portal support
    xdg-desktop-portal-kde
    xdg-desktop-portal-gtk

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
    GTK_THEME = "WhiteSur-dark";
    ICON_THEME = "WhiteSur";
    CURSOR_THEME = "WhiteSur-cursors";
  };

  # XDG portals for better desktop integration
  xdg.portal = {
    enable = true;
    config.common.default = "*";
    extraPortals = with pkgs; [
      xdg-desktop-portal-kde
      xdg-desktop-portal-gtk
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

  # GNOME Keyring daemon for credential storage (works with KDE)
  systemd.user.services.gnome-keyring-daemon = {
    description = "GNOME Keyring daemon for secure credential storage";
    wantedBy = [ "graphical-session.target" ];
    after = [ "dbus.service" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = "GNOME_KEYRING_CONTROL=/run/user/%u/keyring/control";
    };
  };
}
