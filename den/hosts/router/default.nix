{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkHostModule {
  name = "router";
  primaryUser = "deepwatrcreatur";
  aspectsList = [
    "nixos-base"
    "router-router"
  ];
  extraImports = [
    ../../../hosts/nixos/router/hardware-configuration.nix
    ../../../hosts/nixos/router/disko.nix
    ../../../hosts/nixos/router/networking.nix
    ../../../hosts/nixos/router/caddy.nix
  ];
}
