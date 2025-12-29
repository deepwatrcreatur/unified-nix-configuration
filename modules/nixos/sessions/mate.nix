{ config, pkgs, lib, ... }:

{
  # ===========================================
  # Base Configuration
  # ===========================================

  # Enable X11 windowing system.
  services.xserver.enable = true;

  # Enable MATE desktop environment.
  services.xserver.desktopManager.mate.enable = true;

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
  # MATE-Specific Packages
  # ===========================================

  environment.systemPackages = with pkgs; [
    # MATE-specific settings plugins
    mate.mate-settings-daemon
  ];

  # ===========================================
  # XDG Portals for MATE
  # ===========================================

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-mate
    ];
  };

  # ===========================================
  # MATE Panel Notes
  # ===========================================
  # MATE's panel includes a workspace switcher, and its window manager,
  # Marco, allows for moving windows between workspaces.
  #
  # For macOS Look with Multiple Panels:
  # 1. Right-click panel → Add to Panel → Workspace Switcher (top left)
  # 2. Right-click panel → Add to Panel → Status area (top right)
  # 3. Right-click panel → Properties:
  #    - Set size to small (24-32px)
  #    - Enable transparency with WhiteSur theme
  # 4. Use WhiteSur-dark theme for transparent panel effect
}
