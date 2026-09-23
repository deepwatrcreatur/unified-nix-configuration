# den/aspects/inference-ollama.nix
# GPU-accelerated inference aspect with Ollama and Tesla P40 support via tesla-inference-flake.
_context:
{
  pkgs,
  lib,
  config,
  ...
}:
{
  # Allow unfree packages, cuDNN, and CUDA packages
  nixpkgs.config.allowUnsupportedSystem = true;
  nixpkgs.config.cudaForwardCompat = false;

  tesla-inference = {
    enable = true;
    gpu = "P40";
    monitoring.enable = true;
    ollama = {
      enable = true;
      package = pkgs.ollama-official-binaries;
      host = "0.0.0.0";
      port = 11434;
      modelsPath = "/var/lib/ollama";
      environmentVariables = {
        CUDA_VISIBLE_DEVICES = "0";
        OLLAMA_GPU_OVERHEAD = "0";
        LD_LIBRARY_PATH = "/run/opengl-driver/lib";
      };
    };
  };

  # Disable power management for Tesla P40 stability
  hardware.nvidia.powerManagement.enable = lib.mkDefault false;

  # Ensure overcommit memory allows large LLM model mappings without aborting
  boot.kernel.sysctl."vm.overcommit_memory" = 1;
}
