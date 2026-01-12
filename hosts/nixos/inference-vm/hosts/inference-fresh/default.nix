{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Hardware configuration
    ./hardware-configuration.nix

    # Import untouched modules from main config
    ../../modules/storage.nix
    ../../modules/users.nix
    ../../modules/packages.nix
    # Omitting ollama.nix and gpu-nvidia.nix as requested

    # Import modified version from fresh-nixos branch
    ./modules/configuration.nix
  ];

  boot.growPartition = true;

  # Host-specific configuration
  networking.hostName = "inference-fresh";
}
