{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkHostModule {
  name = "inference3";
  primaryUser = "deepwatrcreatur";
  extraImports = [
    ../../../hosts/nixos/inference-vm/hosts/inference3/hardware-configuration.nix
    (
      { ... }:
      {
        networking.hostName = "inference3";
        boot.growPartition = true;
      }
    )
  ];
  aspectsList = [
    "inference-vm-base"
  ];
}
