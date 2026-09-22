{ lib, inputs, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkInventoryHostModule {
  name = "emerald";
  primaryUser = "deepwatrcreatur";
  primaryUserImports = [
    ../../../users/deepwatrcreatur/hosts/emerald
  ];
  extraImports = [
    inputs.disko.nixosModules.disko
    ../../../hosts/nixos/emerald/disko.nix
    ../../../hosts/nixos/emerald/hardware-configuration.nix
    ../../../hosts/nixos/emerald/networking.nix
    {
      boot.loader.systemd-boot.enable = lib.mkDefault true;
      boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
    }
  ];
}
