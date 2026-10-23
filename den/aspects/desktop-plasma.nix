# den/aspects/desktop-plasma.nix
# KDE Plasma 6 desktop aspect with SDDM display manager, KWallet integration, and Vicinae launcher.
{
  primaryUser ? "deepwatrcreatur",
  ...
}:
{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../../modules/nixos/sessions/plasma-session-base.nix
  ];

  # Graphics & audio defaults for workstation desktop
  hardware.graphics.enable = lib.mkDefault true;
  services.pipewire = {
    enable = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
  };
  security.polkit.enable = true;

  home-manager.users.${primaryUser} = {
    programs.vicinae.enable = true;
  };
}
