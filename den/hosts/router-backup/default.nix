{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkInventoryHostModule {
  name = "router-backup";
  primaryUser = "deepwatrcreatur";
  primaryUserImports = [
    ../../../users/deepwatrcreatur/hosts/router-backup/default.nix
  ];
  extraImports = [
    ../../../hosts/nixos/router-backup/hardware-configuration.nix
    ../../../hosts/nixos/router-backup/networking.nix
    ../../../hosts/nixos/router-backup/caddy.nix
    ../../../hosts/nixos/router-backup/configuration.nix
  ];
}
