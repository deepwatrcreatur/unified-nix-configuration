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
    # Temporarily disable to fix home-manager startup failure
    # ../../../../modules/home-manager/inference-ollama.nix
  ];

  # Set home-manager state version (match current working generation)
  home.stateVersion = lib.mkForce "25.05";

  # Inference-specific packages (minimal, conservative versions)
  home.packages = with pkgs; [
    # Use Python 3.12 for better compatibility (matches working Ubuntu setups)
    python312
    python312Packages.pip
    python312Packages.numpy
    python312Packages.matplotlib

    # Additional tools for inference work
    httpie # jq is already in common packages

    # AI/ML tools - install via pip in venv for better compatibility
    # python312Packages.torch  # Install via pip instead
    # CUDA debugging tools - re-enable after base system is stable
    # cudaPackages.cuda_gdb
  ];

  # Temporarily disable Ollama home-manager integration to fix startup failure
  # programs.inference-ollama = {
  #   enable = true;
  #   isRoot = false;
  # };

  # Inference-specific shell aliases (non-Ollama)
  programs.nushell.shellAliases = {
    # Temporarily disable GPU tools that require CUDA packages
    # gpu-status = "nvidia-smi";
    # inference-monitor = "nvtop";
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
