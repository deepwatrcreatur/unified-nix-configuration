{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkHostModule {
  name = "inference2";
  primaryUser = "deepwatrcreatur";
  extraImports = [
    ../../../hosts/nixos/inference-vm/hosts/inference2/hardware-configuration.nix
    (
      { ... }:
      {
        networking.hostName = "inference2";
        boot.growPartition = true;
      }
    )
  ];
  aspectsList = [
    "inference-vm-base"
  ];
}
