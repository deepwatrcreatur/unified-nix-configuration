{ config, pkgs, ... }:

{
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the LXDE desktop environment.
  services.xserver.desktopManager.lxde.enable = true;

  # Install plank for a dock.
  environment.systemPackages = with pkgs; [
    plank
  ];

  # LXDE is very lightweight. It uses Openbox as its window manager,
  # which supports workspaces and moving windows between them.
  # However, getting workspace *previews* might require a separate
  # compositor or widget that is not included by default.
  # The default pager shows workspaces without previews.
}
