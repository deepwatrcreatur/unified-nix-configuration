# Emergency safe-mode recovery specialization aspect.
# Provides an alternative bootloader entry ('safemode-tty') with minimal TTY / IceWM fallback
# for quick recovery when Wayland compositors or display managers crash, hang, or fail to start.
{ ... }:
{ lib, ... }:
{
  imports = [
    ../../modules/nixos/specializations/safe-mode.nix
  ];

  myModules.specializations.safeMode.enable = lib.mkDefault true;
}
