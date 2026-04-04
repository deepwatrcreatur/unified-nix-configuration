{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Legacy path: inference VM outputs are moving to den leaves and aspects.
  # Keep this file only while the fresh-host experiment still depends on the
  # older tree layout.
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
