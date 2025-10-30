# Enable both Wayland and X11 sessions for GNOME
{ config, pkgs, lib, ... }:

{
  # Ensure X11 support is enabled alongside Wayland
  services.xserver = {
    enable = true;
    # Enable X11 session support for GNOME
    desktopManager.gnome.sessionPath = [ pkgs.gnome-session ];
  };

  # Configure GDM for X11 only when GNOME is enabled (Wayland disabled for AMD GPU stability)
  services.xserver.displayManager.gdm = lib.mkIf (config.services.desktopManager.gnome.enable) {
    enable = true;
    # Disable Wayland to avoid AMD GPU crashes
    wayland = false;
    
    # X11 only configuration
    settings = {
      daemon = {
        # Disable Wayland entirely for stability
        WaylandEnable = false;
      };
      security = {
        # Disable automatic login to force session selection
        AutomaticLoginEnable = false;
      };
    };
  };

  # Ensure both session types are available in the greeter
  environment.systemPackages = with pkgs; [
    gnome-session  # Required for GNOME on X11
  ];

  # XDG portals for both Wayland and X11 compatibility
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    config.common.default = "*";
  };
}