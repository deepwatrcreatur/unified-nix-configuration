{ config, pkgs, inputs, ... }:

{
  # Allow unfree packages for CUDA/NVIDIA tools
  nixpkgs.config.allowUnfree = true;
  imports = [
    ../../default.nix
    ./nh.nix
  ];

  home.homeDirectory = "/home/deepwatrcreatur";

  home.packages = with pkgs; [
    # GPU monitoring and tools
    nvtopPackages.nvidia  # NVIDIA GPU monitor
    gpustat               # Simple GPU utilization viewer
    glxinfo              # OpenGL info
    vulkan-tools         # Vulkan utilities
    nvitop               # Alternative GPU process monitor
  ];

  home.stateVersion = "24.11";
}
