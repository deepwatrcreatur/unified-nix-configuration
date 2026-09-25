# den/aspects/deep-focus.nix
# Distraction-free deep-focus bootloader specialization aspect.
# Configures notification silence (Do-Not-Disturb), suppresses non-essential background
# maintenance/update checks, and establishes focused desktop workspace settings.
{ ... }:
{ lib, ... }:
{
  imports = [
    ../../modules/nixos/specializations/deep-focus.nix
  ];

  myModules.specializations.deepFocus.enable = lib.mkDefault true;
}
