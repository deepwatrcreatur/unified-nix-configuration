{ config, pkgs, lib, inputs, ... }:

{
  # Inference VM specific configuration for deepwatrcreatur
  imports = [
    ../.. # Import default user config
    ../../just.nix
    ../../../../modules/home-manager/gpg-cli.nix
  ];

  # Inference-specific packages (only what's not in common)
  home.packages = with pkgs; [
    # AI/ML tools  
    python3
    python3Packages.pip
    python3Packages.torch
    python3Packages.numpy
    python3Packages.matplotlib
    
    # Additional tools for inference work
    httpie  # jq is already in common packages
    
    # CUDA debugging and monitoring tools
    cudaPackages.cuda_gdb
  ];

  # Inference-specific shell aliases (nushell aliases handled by common modules)
  programs.nushell.shellAliases = {
    ollama-status = "systemctl status ollama";
    ollama-logs = "journalctl -u ollama -f";  
    gpu-status = "nvidia-smi";
    models = "ls -la /models/";
    inference-monitor = "nvtop";
  };

  # Environment variables for inference
  home.sessionVariables = {
    OLLAMA_HOST = "0.0.0.0:11434";
    CUDA_VISIBLE_DEVICES = "0";  # Use first GPU
  };

  # Override secrets activation for inference VMs - disable GPG key decryption to prevent failures
  services.secrets-activation = {
    enable = true;
    secretsPath = toString ../../secrets;
    continueOnError = lib.mkForce true;  # Be more lenient for inference VMs
    enableBitwardenDecryption = lib.mkForce false;  # Not needed for inference work
    enableGpgKeyDecryption = lib.mkForce false;     # Not needed for inference work, prevents log exposure
  };
}
