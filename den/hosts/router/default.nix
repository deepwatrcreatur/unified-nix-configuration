{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkInventoryHostModule {
  name = "router";
  primaryUser = "deepwatrcreatur";
  primaryUserImports = [
    ../../../users/deepwatrcreatur/hosts/router
  ];
  extraImports = [
    ../../../hosts/nixos/router/hardware-configuration.nix
    ../../../hosts/nixos/router/networking.nix
    ../../../hosts/nixos/router/caddy.nix
    ../../../hosts/nixos/router/disko.nix
    ../../../hosts/nixos/router/configuration.nix
  ];
}
