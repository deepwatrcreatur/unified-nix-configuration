{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkHostModule {
  name = "router-bootstrap";
  primaryUser = "deepwatrcreatur";
  aspectsList = [
    "nixos-base"
    "bootstrap-base"
  ];
  extraImports = [
    ../../../hosts/nixos/router-bootstrap/hardware-configuration.nix
  ];
}
