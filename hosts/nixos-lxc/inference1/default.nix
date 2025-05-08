{ lib, pkgs, config, inputs, hostName, ... }: # hostName is injected by the flake

{
  imports = [
    # Instance-specific hardware configuration
    ./hardware-configuration.nix

    # Shared module for all inference-type VMs
    ../../../modules/nixos/common-inference-vm.nix
  ];

  # Set the unique hostname for this specific instance
  networking.hostName = inference1;
}

