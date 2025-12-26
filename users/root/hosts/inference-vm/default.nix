{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # Inference VM specific configuration for root
  imports = [
    ../.. # Import default root config
    ../../../../modules/home-manager/inference-ollama.nix
  ];

  # Set home-manager state version
  home.stateVersion = "25.11";

  # Root-specific packages for inference management (only what's not in common)
  home.packages = with pkgs; [
    # Network tools for debugging
    netcat
    tcpdump

    # System administration (lsof, strace likely in common)

    # CUDA debugging tools
    cudaPackages.cuda_gdb
  ];

  # Enable Ollama home-manager integration for root
  programs.inference-ollama = {
    enable = true;
    isRoot = true;
  };

  # Root shell aliases for inference administration (non-Ollama)
  programs.nushell.shellAliases = {
    gpu-status = "nvidia-smi";
    gpu-processes = "nvidia-smi pmon";
  };

  # Root environment for inference administration (non-Ollama)
  home.sessionVariables = {
    NVIDIA_VISIBLE_DEVICES = "all";
  };
}
