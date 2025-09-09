{ config, lib, pkgs, ... }:

{
  # NVIDIA GPU configuration
  services.xserver.videoDrivers = ["nvidia"];
  hardware.graphics.enable = true;
  
  hardware.nvidia = {
    # Modesetting is required
    modesetting.enable = true;

    # Nvidia power management - disabled for P40
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # Use proprietary driver (not open source)
    open = false;

    # Enable nvidia-settings
    nvidiaSettings = true;
    
    # Use stable driver package
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # CUDA environment
  environment.variables = {
    GGML_CUDA = "1";
    CUDA_HOME = "${pkgs.cudaPackages.cudatoolkit}";
    LD_LIBRARY_PATH = lib.makeLibraryPath [
      "${pkgs.cudaPackages.cudatoolkit}/lib64"
      pkgs.cudaPackages.cudnn
      pkgs.cudaPackages.cuda_cudart
      pkgs.stdenv.cc.cc.lib
    ];
    LLAMA_CPP_MODEL_PATH = "/models/llama_models";
  };

  # CUDA packages
  environment.systemPackages = with pkgs; [
    nvtopPackages.full
    pciutils
    cudaPackages.cudatoolkit
    (llama-cpp.override {
      cudaSupport = true;
      cudaPackages = pkgs.cudaPackages;
    })
  ];
}