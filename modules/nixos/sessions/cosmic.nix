{
  config,
  pkgs,
  lib,
  ...
}:

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
    # Portal configuration for COSMIC with workarounds:
    # - ScreenCast: Use gtk backend (cosmic's implementation has issues)
    # - InputCapture: Use gnome backend (cosmic doesn't implement it yet)
    #   This is required for Deskflow/Input Leap to work on Wayland
    config = {
      common = {
        "org.freedesktop.impl.portal.ScreenCast" = "gtk";
        "org.freedesktop.impl.portal.InputCapture" = "gnome";
        "org.freedesktop.impl.portal.RemoteDesktop" = "gnome";
      };
    };
  };
}
