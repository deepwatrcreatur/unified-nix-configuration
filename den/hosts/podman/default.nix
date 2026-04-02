{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkInventoryHostModule {
  name = "podman";
  primaryUser = "deepwatrcreatur";
  extraGroups = [
    "wheel"
    "podman"
  ];
  primaryUserImports = [
    ../../../users/deepwatrcreatur/hosts/podman
  ];
}
