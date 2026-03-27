{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkHostModule {
  name = "inference1";
  primaryUser = "deepwatrcreatur";
  extraImports = [
    ../../../hosts/nixos/inference-vm/hosts/inference1/hardware-configuration.nix
    (
      { ... }:
      {
        networking.hostName = "inference1";
        boot.growPartition = true;
      }
    )
  ];
  aspectsList = [
    "inference-vm-base"
    "inference1-ollama"
  ];
}
