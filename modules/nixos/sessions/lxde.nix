{ config, pkgs, lib, ... }:

{
  # ===========================================
  # Base Configuration
  # ===========================================

  # Enable X11 windowing system.
  services.xserver.enable = true;

  # Enable LXDE desktop environment.
  services.xserver.desktopManager.lxde.enable = true;

  # ===========================================
  # Import Shared WhiteSur Theme Module
  # ===========================================
  # This provides:
  # - WhiteSur GTK theme, icons, cursor
  # - Plank dock (auto-start)
  # - Font configuration
  # - Environment variables

  imports = [
    ./whitesur-theme.nix
  ];

  # ===========================================
  # XDG Portals for LXDE
  # ===========================================

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # ===========================================
  # LXDE Panel Notes
  # ===========================================
  # LXDE is very lightweight. It uses Openbox as its window manager,
  # which supports workspaces and moving windows between them.
  # However, getting workspace *previews* might require a separate
  # compositor or widget that is not included by default.
  # The default pager shows workspaces without previews.
  #
  # For macOS Look with LXDE:
  # - LXDE Menu → Desktop Preferences → Appearance
  # - Select WhiteSur-dark theme
  # - Panel is at bottom by default
  # - Configure Openbox for transparent effects
}
