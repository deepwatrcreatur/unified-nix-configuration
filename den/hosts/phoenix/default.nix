{ lib, inputs, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkInventoryHostModule {
  name = "phoenix";
  primaryUser = "deepwatrcreatur";
  primaryUserImports = [
    inputs.nix-whitesur-config.homeManagerModules.default
    ../../../users/deepwatrcreatur/hosts/workstation
  ];
  extraImports = [
    ../../../hosts/nixos/phoenix/hardware-configuration.nix
    ../../../hosts/nixos/phoenix/networking.nix
  ];
}
