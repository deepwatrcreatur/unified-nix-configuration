{ lib, ... }:
let
  den = import ../../lib.nix { inherit lib; };
in
den.mkInventoryHostModule {
  name = "inference-fresh";
  primaryUser = "deepwatrcreatur";
  extraImports = [
    ../../../hosts/nixos/inference-vm/hosts/inference-fresh/hardware-configuration.nix
    (
      { ... }:
      {
        networking.hostName = "inference-fresh";
        boot.growPartition = true;
      }
    )
  ];
  # No inference-vm-nvidia: this host has no GPU and runs without NVIDIA drivers.
}
