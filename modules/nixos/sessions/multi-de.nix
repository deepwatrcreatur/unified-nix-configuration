# Multi-Desktop Environment Configuration
# Enables multiple DEs simultaneously - switch between them at the login screen
# without needing to rebuild NixOS each time.
#
# At the LightDM login screen, click the session selector to choose:
# - Cinnamon
# - MATE
# - XFCE
#
# NOTE: GNOME cannot coexist with Cinnamon due to NIX_GSETTINGS_OVERRIDES_DIR conflict.
# If you need GNOME, use garuda-themed-gnome.nix instead.
#
{ config, pkgs, ... }:

{
  imports = [
    # Import existing DE modules - they each enable their respective DE
    ./cinnamon.nix
    ./mate.nix
    ./xfce.nix
    # ./lxde.nix  # Uncomment to add LXDE
  ];

  # Display Manager - LightDM works well with multiple non-GNOME sessions
  # (GDM has issues when GNOME isn't the primary DE)
  services.xserver.displayManager.lightdm = {
    enable = true;
    greeters.slick = {
      enable = true;
      extraConfig = ''
        show-hostname=true
      '';
    };
  };

  # Optional: Auto-login (comment out to always see session selector)
  # services.displayManager.autoLogin = {
  #   enable = true;
  #   user = "deepwatrcreatur";
  # };

  # Additional common packages useful across all DEs
  environment.systemPackages = with pkgs; [
    # Theming tools
    dconf-editor

    # Icon themes
    beauty-line-icon-theme
    candy-icons
    capitaine-cursors

    # Fonts
    fira-code
    noto-fonts
    noto-fonts-color-emoji
  ];

  # GTK theming support
  programs.dconf.enable = true;

  # XDG portals for desktop integration
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
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