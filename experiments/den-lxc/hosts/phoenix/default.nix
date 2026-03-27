{ lib, ... }:
let
  denPrototype = import ../../lib.nix { inherit lib; };
in
denPrototype.mkHostModule {
  name = "phoenix";
  primaryUser = "deepwatrcreatur";
  extraImports = [
    ../../../../hosts/nixos/phoenix/hardware-configuration.nix
    ../../../../hosts/nixos/phoenix/networking.nix
  ];
  aspectsList = [
    "nixos-base"
    "workstation-desktop"
  ];
}
