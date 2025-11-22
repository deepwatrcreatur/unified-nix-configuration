{ config, pkgs, ... }:

{
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the Cinnamon desktop environment.
  services.xserver.desktopManager.cinnamon.enable = true;

  # Cinnamon's panel can be configured to act as a dock, so no extra package
  # is needed. It also includes a workspace switcher with previews and
  # supports moving windows between workspaces with the mouse.
}
