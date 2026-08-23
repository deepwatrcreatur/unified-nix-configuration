{
  lib,
  ...
}:

{
  imports = [
    ../../../profiles/nixos/workstation.nix
    ./disko.nix
    ./hardware-configuration.nix
    ./networking.nix
  ];

  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    limine.enable = true;
    efi.canTouchEfiVariables = true;
  };
}
