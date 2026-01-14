{ config, pkgs, ... }:

{
  imports = [
    # ../../home-manager/hyprland/default.nix # TEMPORARILY DISABLED
    # ../whitesur-theme.nix # TEMPORARILY DISABLED
  ];

  # Enable the Hyprland Wayland compositor # TEMPORARILY DISABLED
  programs.hyprland = {
    enable = false; # TEMPORARILY DISABLED
    xwayland.enable = false; # TEMPORARILY DISABLED
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

  # System-level packages # TEMPORARILY DISABLED
  # environment.systemPackages = with pkgs; [ # TEMPORARILY DISABLED
  #   swaylock-effects # TEMPORARILY DISABLED

  #   # Hyprland ecosystem # TEMPORARILY DISABLED
  #   hyprpaper # Wallpaper utility # TEMPORARILY DISABLED
  #   hypridle  # Idle management daemon # TEMPORARILY DISABLED
  #   hyprlock  # Screen locker # TEMPORARILY DISABLED
  #   xdg-desktop-portal-hyprland # TEMPORARILY DISABLED
  #   waybar # Status bar # TEMPORARILY DISABLED
  #   wofi   # Application launcher # TEMPORARILY DISABLED
    
  #   # Utilities # TEMPORARILY DISABLED
  #   pavucontrol # Volume control # TEMPORARILY DISABLED
  #   networkmanagerapplet # Network manager applet # TEMPORARILY DISABLED
  #   brightnessctl # TEMPORARILY DISABLED
  #   wl-clipboard # Clipboard tool for wayland # TEMPORARILY DISABLED
    
  #   # Themeing # TEMPORARILY DISABLED
  #   libsForQt5.qt5ct # TEMPORARILY DISABLED
    
  #   # Fonts # TEMPORARILY DISABLED
  #   noto-fonts # TEMPORARILY DISABLED
  #   noto-fonts-cjk # TEMPORARILY DISABLED
  #   noto-fonts-emoji # TEMPORARILY DISABLED
    
  #   # Apps from cosmic.nix # TEMPORARILY DISABLED
  #   pulseaudio-ctl # TEMPORARILY DISABLED
  #   flameshot # TEMPORARILY DISABLED
  #   copyq # TEMPORARILY DISABLED
  #   dconf # TEMPORARILY DISABLED
  #   gnome-shell-extensions # TEMPORARILY DISABLED
  #   thunderbird # TEMPORARILY DISABLED
  #   libappindicator-gtk3 # TEMPORARILY DISABLED
  #   libsecret # TEMPORARILY DISABLED
  #   gnome-keyring # TEMPORARILY DISABLED
  #   glib # TEMPORARILY DISABLED
  #   gsettings-desktop-schemas # TEMPORARILY DISABLED
  # ]; # TEMPORARILY DISABLED

  # # Fonts # TEMPORARILY DISABLED
  # fonts.packages = with pkgs; [ # TEMPORARILY DISABLED
  #   noto-fonts # TEMPORARILY DISABLED
  #   noto-fonts-cjk # TEMPORARILY DISABLED
  #   noto-fonts-emoji # TEMPORARILY DISABLED
  #   (nerdfonts.override { fonts = [ "JetBrainsMono" ]; }) # TEMPORARILY DISABLED
  # ]; # TEMPORARILY DISABLED
  
  # # Configure environment variables # TEMPORARILY DISABLED
  # environment.variables = { # TEMPORARILY DISABLED
  #   XCURSOR_SIZE = "24"; # TEMPORARILY DISABLED
  #   QT_QPA_PLATFORMTHEME = "qt5ct"; # TEMPORARILY DISABLED
  # }; # TEMPORARILY DISABLED
  
  # # XDG Portals # TEMPORARILY DISABLED
  # xdg.portal = { # TEMPORARILY DISABLED
  #   enable = false; # TEMPORARILY DISABLED
  #   extraPortals = with pkgs; [ # TEMPORARILY DISABLED
  #     xdg-desktop-portal-gtk # TEMPORARILY DISABLED
  #   ]; # TEMPORARILY DISABLED
  # }; # TEMPORARILY DISABLED

  # Disable auto-suspend
  # services.logind.idleAction = "ignore"; # Temporarily commented out to fix build error
}
