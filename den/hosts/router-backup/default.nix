{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkHostModule {
  name = "router-backup";
  primaryUser = "deepwatrcreatur";
  aspectsList = [
    "nixos-base"
    "rclone-client"
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
