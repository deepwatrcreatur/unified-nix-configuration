{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkInventoryHostModule {
  name = "router-bootstrap";
  primaryUser = "deepwatrcreatur";
  extraImports = [
    ../../../hosts/nixos/router-bootstrap/hardware-configuration.nix
  ];
}
