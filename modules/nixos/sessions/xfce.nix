{ config, pkgs, ... }:

{
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the XFCE desktop environment.
  services.xserver.desktopManager.xfce.enable = true;

  # Install plank, a simple and elegant dock.
  environment.systemPackages = with pkgs; [
    plank
  ];

  # XFCE's window manager, xfwm4, provides workspace previews and the
  # ability to drag windows between workspaces out of the box. You may
  # need to add the "Workspace Switcher" item to your panel and configure
  # it to show previews.
}
