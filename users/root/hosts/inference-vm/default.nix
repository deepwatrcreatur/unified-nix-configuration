{ config, pkgs, lib, inputs, ... }:

{
  # Inference VM specific configuration for root
  imports = [
    ../.. # Import default root config
  ];

  # Root-specific packages for inference management (only what's not in common)
  home.packages = with pkgs; [
    # Network tools for debugging
    netcat
    tcpdump
    
    # System administration (lsof, strace likely in common)
    
    # CUDA debugging tools
    cudaPackages.cuda_gdb
  ];

  # Root shell aliases for inference administration  
  programs.nushell.shellAliases = {
    ollama-restart = "systemctl restart ollama";
    ollama-status = "systemctl status ollama";  
    ollama-logs = "journalctl -u ollama -n 50";
    gpu-status = "nvidia-smi";
    gpu-processes = "nvidia-smi pmon";
    models-space = "df -h /models";
    inference-services = "systemctl list-units --type=service | grep -E 'ollama|nvidia'";
  };

  # Root environment for inference administration
  home.sessionVariables = {
    OLLAMA_HOST = "0.0.0.0:11434";
    NVIDIA_VISIBLE_DEVICES = "all";
  };
}