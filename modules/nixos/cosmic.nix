{ config, pkgs, lib, ... }:

{
  services.desktopManager.cosmic.enable = true;

  services.displayManager.cosmic-greeter.enable = true;

  # Only add packages not automatically included by cosmic desktop manager
  environment.systemPackages = with pkgs; [
    # No extra cosmic extensions for now, as they might be outdated
  ];

  # Enable XDG portals for COSMIC
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-cosmic
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    # The cosmic portal implementation for screen capture is not working correctly.
    # As a workaround, we explicitly tell xdg-desktop-portal to use the gtk backend
    # for screen sharing.
    config = {
      "org.freedesktop.impl.portal.ScreenCast" = "gtk";
    };
  };
}
