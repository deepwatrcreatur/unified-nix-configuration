{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkInventoryHostModule {
  name = "phoenix";
  primaryUser = "deepwatrcreatur";
  extraImports = [
    ../../../hosts/nixos/phoenix/hardware-configuration.nix
    ../../../hosts/nixos/phoenix/networking.nix
  ];
}
