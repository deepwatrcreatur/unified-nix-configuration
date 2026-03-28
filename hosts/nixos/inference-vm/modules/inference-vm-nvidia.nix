{ pkgs, ... }:

# NVIDIA driver configuration for GPU inference VMs (Tesla P40 / Pascal class).
# Separated from configuration.nix so that non-GPU inference hosts (e.g.
# inference-fresh) can use inference-vm-base without pulling in NVIDIA drivers.
{
  nixpkgs.config.allowUnsupportedSystem = true; # allow cuDNN and CUDA packages
  nixpkgs.config.cudaForwardCompat = false; # skip cuda_compat build overhead

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false; # disable for Tesla P40 stability
    open = false; # use proprietary driver
  };
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  # OpenWebUI — web interface for Ollama; only meaningful with GPU-backed inference
  environment.systemPackages = with pkgs; [
    open-webui
  ];
}
