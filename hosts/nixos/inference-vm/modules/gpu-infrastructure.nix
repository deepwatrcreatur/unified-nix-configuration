{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.inference.gpu;
in
{
  options.inference.gpu = {
    enable = lib.mkEnableOption "GPU infrastructure (NVIDIA CUDA stack) for inference";

    nvidia = {
      enable = lib.mkEnableOption "NVIDIA GPU support";

      powerManagement = {
        enable = lib.mkEnableOption "NVIDIA GPU power management";
        finegrained = lib.mkEnableOption "Fine-grained GPU power management";
      };

      useOpenDriver = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Use open-source NVIDIA driver (nouveau) instead of proprietary driver";
      };
    };

    cuda = {
      enable = lib.mkEnableOption "CUDA toolkit for GPU compute";

      enableTeslaP40 = lib.mkEnableOption "Enable Tesla P40 specific optimizations";

      package = lib.mkOption {
        type = lib.types.package;
        default = config.boot.kernelPackages.nvidiaPackages.latest;
        description = "NVIDIA driver package to use";
      };
    };

    monitoring = {
      enable = lib.mkEnableOption "GPU monitoring tools";
    };
  };

  config = lib.mkIf cfg.enable {
    # Hardware graphics configuration
    hardware.graphics.enable = true;

    # NVIDIA driver setup
    services.xserver.videoDrivers = lib.mkIf cfg.nvidia.enable [
      (if cfg.nvidia.useOpenDriver then "nouveau" else "nvidia")
    ];

    hardware.nvidia = lib.mkIf cfg.nvidia.enable {
      modesetting.enable = !cfg.nvidia.useOpenDriver;
      powerManagement.enable = cfg.nvidia.powerManagement.enable;
      powerManagement.finegrained = cfg.nvidia.powerManagement.finegrained;
      open = cfg.nvidia.useOpenDriver;
      nvidiaSettings = !cfg.nvidia.useOpenDriver;
      package = cfg.cuda.package;
    };

    # CUDA toolkit and libraries
    environment.systemPackages = lib.optionals cfg.cuda.enable [
      cfg.cuda.package.cuda_toolkit
      pkgs.cuda-toolkit_12
      pkgs.cudatoolkit
      pkgs.libcublas
      pkgs.libcusparse
      pkgs.libcurand
    ];

    # GPU monitoring tools
    environment.systemPackages = lib.optionals cfg.monitoring.enable [
      pkgs.nvitop  # Modern GPU monitoring tool
      pkgs.gpu-burn
    ];

    # Environment variables for CUDA
    environment.variables = lib.mkIf cfg.cuda.enable {
      CUDA_PATH = "${cfg.cuda.package.cudatoolkit}";
      CUDA_HOME = "${cfg.cuda.package.cudatoolkit}";
    };

    # Allow unfree packages (NVIDIA drivers and CUDA)
    nixpkgs.config.allowUnfree = true;
  };
}
