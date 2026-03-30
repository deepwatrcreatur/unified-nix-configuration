{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkHostModule {
  name = "gateway";
  primaryUser = "deepwatrcreatur";
  aspectsList = [
    "nixos-base"
    "gateway-router"
  ];
  extraImports = [
    ../../../hosts/nixos/gateway/hardware-configuration.nix
    ../../../hosts/nixos/gateway/networking.nix
    ../../../hosts/nixos/gateway/caddy.nix
  ];
}
