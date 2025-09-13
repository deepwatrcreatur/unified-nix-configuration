{ config, pkgs, lib, inputs, ... }:

{
  # All settings identical for inference1, inference2, inference3
  # DO NOT set networking.hostName here.
  # DO NOT import hardware-configuration.nix here.

  imports = [
    # Import all common inference VM modules
    ../../../hosts/nixos/inference-vm/modules/configuration.nix
    ../../../hosts/nixos/inference-vm/modules/gpu-nvidia.nix
    ../../../hosts/nixos/inference-vm/modules/ollama.nix
    ../../../hosts/nixos/inference-vm/modules/storage.nix
    ../../../hosts/nixos/inference-vm/modules/users.nix
    ../../../hosts/nixos/inference-vm/modules/packages.nix
    # Use common nix-settings instead of custom nix-config
    ../../common/nix-settings.nix
    # Add GPG CLI support for git signing
    ../../home-manager/gpg-cli.nix
  ];

  # Remote building configuration (inference-specific)
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "10.10.11.39";
      system = "x86_64-linux";
      maxJobs = 8;
      speedFactor = 2;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      sshUser = "deepwatrcreatur";
      sshKey = "/root/.ssh/nix-remote";
    }
  ];

  # Common DHCP settings for all inference VMs
  networking.useDHCP = lib.mkDefault true;
  networking.interfaces.enp1s0.useDHCP = lib.mkDefault true;
}
