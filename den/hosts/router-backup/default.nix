{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkHostModule {
  name = "router-backup";
  primaryUser = "deepwatrcreatur";
  primaryUserImports = [
    ../../../users/deepwatrcreatur/hosts/router-backup/default.nix
  ];
  aspectsList = [
    "nixos-base"
    "home-manager-users"
    "github-token-client"
    "router-router"
  ];
  extraImports = [
    ../../../hosts/nixos/router-backup/hardware-configuration.nix
    ../../../hosts/nixos/router-backup/networking.nix
    ../../../hosts/nixos/router-backup/caddy.nix
    ../../../hosts/nixos/router-backup/configuration.nix
  ];
}
