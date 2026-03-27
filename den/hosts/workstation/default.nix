{ lib, ... }:
let
  denPrototype = import ../../lib.nix { inherit lib; };
in
denPrototype.mkHostModule {
  name = "workstation";
  primaryUser = "deepwatrcreatur";
  extraImports = [
    ../../../hosts/nixos/workstation/hardware-configuration.nix
    ../../../hosts/nixos/workstation/networking.nix
  ];
  aspectsList = [
    "nixos-base"
    "workstation-desktop"
  ];
}
