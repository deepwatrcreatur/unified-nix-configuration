{ config, pkgs, ... }:

{
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the MATE desktop environment.
  services.xserver.desktopManager.mate.enable = true;

  # Install plank for a dock.
  environment.systemPackages = with pkgs; [
    plank
  ];

  # MATE's panel includes a workspace switcher, and its window manager,
  # Marco, allows for moving windows between workspaces.
}
