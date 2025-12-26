{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # Inference VM specific configuration for deepwatrcreatur
  imports = [
    ../.. # Import default user config
    ../../../../modules/home-manager
    ../../../../modules/home-manager/gpg-cli.nix
    ../../../../modules/home-manager/just.nix
    ../../../../modules/home-manager/just-nixos.nix
    ../../../../modules/home-manager/inference-ollama.nix
  ];

  # Set home-manager state version
  home.stateVersion = "25.11";

  # Inference-specific packages (only what's not in common)
  home.packages = with pkgs; [
    # AI/ML tools
    python3
    python3Packages.pip
    python3Packages.torch
    python3Packages.numpy
    python3Packages.matplotlib

    # Additional tools for inference work
    httpie # jq is already in common packages

    # CUDA debugging and monitoring tools (temporarily disabled due to build issues)
    # cudaPackages.cuda_gdb
  ];

  # Enable Ollama home-manager integration
  programs.inference-ollama = {
    enable = true;
    isRoot = false;
  };

  # Inference-specific shell aliases (non-Ollama)
  programs.nushell.shellAliases = {
    gpu-status = "nvidia-smi";
    inference-monitor = "nvtop";
  };

  # Environment variables for inference (non-Ollama)
  home.sessionVariables = {
    CUDA_VISIBLE_DEVICES = "0"; # Use first GPU
  };

  # Override secrets activation for inference VMs - disable GPG key decryption to prevent failures
  services.secrets-activation = {
    enable = true;
    secretsPath = toString ../../secrets;
    continueOnError = lib.mkForce true; # Be more lenient for inference VMs
    enableBitwardenDecryption = lib.mkForce false; # Not needed for inference work
    enableGpgKeyDecryption = lib.mkForce false; # Not needed for inference work, prevents log exposure
  };
}
