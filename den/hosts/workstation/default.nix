{ lib, inputs, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkInventoryHostModule {
  name = "workstation";
  primaryUser = "deepwatrcreatur";
  primaryUserImports = [
    inputs.nix-whitesur-config.homeManagerModules.default
    ../../../users/deepwatrcreatur/hosts/workstation
  ];
  extraImports = [
    ../../../hosts/nixos/workstation/hardware-configuration.nix
    ../../../hosts/nixos/workstation/networking.nix
  ];
}
