# Configuration for KDE Plasma with Garuda Dragonized theming elements, forced to use X11
{
  lib,
  ...
}:

{
  imports = [
    ./plasma-session-base.nix
    ./garuda-plasma-theme.nix
  ];

  services.xserver.enable = true;

  services.displayManager.defaultSession = lib.mkForce "plasmax11";
}
