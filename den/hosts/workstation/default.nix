{ lib, inputs, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkHostModule {
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
  aspectsList = [
    "nixos-base"
    "home-manager-users"
    "workstation-desktop"
  ];
}
