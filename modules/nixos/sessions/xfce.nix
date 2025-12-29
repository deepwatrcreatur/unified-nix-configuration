{ config, pkgs, lib, ... }:

{
  # ===========================================
  # Base Configuration
  # ===========================================

  # Enable X11 windowing system.
  services.xserver.enable = true;

  # Enable XFCE desktop environment.
  services.xserver.desktopManager.xfce.enable = true;

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
  # XFCE-Specific Packages
  # ===========================================

  environment.systemPackages = with pkgs; [
    xfce.xfce4-settings-plugin
  ];

  # ===========================================
  # XDG Portals for XFCE
  # ===========================================

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-xfce
    ];
  };

  # ===========================================
  # XFCE Panel Notes
  # ===========================================
  # XFCE's window manager, xfwm4, provides workspace previews and
  # ability to drag windows between workspaces out of box.
  #
  # Panel Customization for macOS Look:
  # 1. Settings → Panel → Add new panel (top)
  # 2. Set panel size to small (24-32px)
  # 3. Enable panel transparency
  # 4. Center panel items
  # 5. Use WhiteSur-dark theme for transparent panel effect
}
