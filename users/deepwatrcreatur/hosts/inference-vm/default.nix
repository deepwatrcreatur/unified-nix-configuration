{ config, pkgs, lib, inputs, ... }:

{
  # Inference VM specific configuration for deepwatrcreatur
  imports = [
    ../.. # Import default user config
    ../../just.nix
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
    
    # CUDA debugging tools
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
}
