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
    enable = lib.mkEnableOption "GPU infrastructure for inference workloads";

    nvidia = {
      enable = lib.mkEnableOption "NVIDIA GPU support";

      package = lib.mkOption {
        type = lib.types.package;
        default = config.boot.kernelPackages.nvidiaPackages.stable;
        description = "NVIDIA driver package to use";
      };

      enableSettings = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable nvidia-settings GUI tool";
      };

      powerManagement = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable NVIDIA power management";
        };

        finegrained = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable fine-grained power management";
        };
      };

      useOpenDriver = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use open-source NVIDIA driver instead of proprietary";
      };
    };

    cuda = {
      enable = lib.mkEnableOption "CUDA support for inference applications";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.cudaPackages;
        description = "CUDA packages to use";
      };

      architectures = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "70" "75" "80" "86" "89" "90" ];
        description = "CUDA compute architectures to support";
      };

      enableTeslaP40 = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable support for Tesla P40 (adds compute capability 6.1)";
      };
    };

    monitoring = {
      enable = lib.mkEnableOption "GPU monitoring tools";

      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [ nvitop ]; # Use nvitop instead of nvtop
        description = "Additional GPU monitoring packages";
      };
    };
  };

  config = lib.mkMerge [
    # Basic GPU infrastructure when enabled
    (lib.mkIf cfg.enable {
      # Basic graphics support
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      # Add GPU monitoring tools to system packages
      environment.systemPackages = lib.optionals cfg.monitoring.enable (
        cfg.monitoring.packages ++ [ pkgs.pciutils ] # lspci for GPU detection
      );
    })

    # NVIDIA-specific configuration
    (lib.mkIf (cfg.enable && cfg.nvidia.enable) {
      # Enable NVIDIA driver
      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement = cfg.nvidia.powerManagement;
        open = cfg.nvidia.useOpenDriver;
        nvidiaSettings = cfg.nvidia.enableSettings;
        package = cfg.nvidia.package;
      };

      # Add nvidia-smi to system packages (comes with driver)
      environment.systemPackages = with pkgs; [
        # nvidia-smi is included with the driver
      ];
    })

    # CUDA-specific configuration
    (lib.mkIf (cfg.enable && cfg.cuda.enable) {
      # CUDA support in nixpkgs
      nixpkgs.config = {
        cudaSupport = true;
        allowUnfree = true; # CUDA packages are unfree
      };

      # Make CUDA available system-wide
      environment.systemPackages = with cfg.cuda.package; [
        cuda_runtime
        cuda_nvcc
        libcublas
        libcufft
        libcurand
        libcusolver
        libcusparse
        cudnn
      ];

      # CUDA environment variables
      environment.variables = {
        CUDA_PATH = "${cfg.cuda.package.cudatoolkit}";
        CUDA_ROOT = "${cfg.cuda.package.cudatoolkit}";
        CUDNN_PATH = "${cfg.cuda.package.cudnn}";
      };

      # Note: computeArchitectures will be available to other modules via cfg.cuda.architectures
    })
  ];
}