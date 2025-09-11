# Enable both Wayland and X11 sessions for GNOME
{ config, pkgs, ... }:

{
  # Ensure X11 support is enabled alongside Wayland
  services.xserver = {
    enable = true;
    # Enable X11 session support for GNOME
    desktopManager.gnome.sessionPath = [ pkgs.gnome-session ];
  };

  # Configure GDM to support both Wayland and X11 sessions
  services.displayManager.gdm = {
    # Don't disable Wayland - keep both options available
    wayland = true;
    
    # Enable X11 fallback and session selection
    settings = {
      daemon = {
        # Allow users to choose between Wayland and X11
        WaylandEnable = true;
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