{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Legacy path: the active `.#inference-fresh` output is built from
  # `den/hosts` and den aspects. Keep this file only while the fresh-host
  # experiment still depends on the older tree layout. Do not land active
  # inference-fresh fixes here first.
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
