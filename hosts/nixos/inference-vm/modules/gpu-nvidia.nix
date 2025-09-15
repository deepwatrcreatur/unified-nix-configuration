{ config, lib, pkgs, ... }:

{
  # NVIDIA GPU configuration - use binary packages only
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

    # Use stable driver package - prefer binary substitutes
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Force binary packages for GPU-related components
  nixpkgs.config = {
    allowUnfree = true;
    # Use CUDA 12.6 for Pascal GPU compatibility (P40)
    cudaSupport = true;
    preferLocalBuild = false;
    # Pin to CUDA 12.6 - last version with full Pascal support
    cudaCapabilities = [ "6.1" ]; # Tesla P40 compute capability
    cudaForwardCompat = false;
  };

  # Use CUDA 12.6 packages for Pascal compatibility
  environment.variables = {
    CUDA_HOME = "${pkgs.cudaPackages_12_6.cudatoolkit}";
    LD_LIBRARY_PATH = lib.makeLibraryPath [
      "${pkgs.cudaPackages_12_6.cudatoolkit}/lib64"
      "${pkgs.cudaPackages_12_6.cudatoolkit}/lib"
      pkgs.cudaPackages_12_6.cuda_cudart.lib
      config.boot.kernelPackages.nvidiaPackages.stable
      pkgs.stdenv.cc.cc.lib
    ];
  };

  # CUDA 12.6 packages for Pascal GPU compatibility
  environment.systemPackages = with pkgs; [
    nvtopPackages.full
    pciutils
    cudaPackages_12_6.cudatoolkit
    cudaPackages_12_6.cuda_cudart
    (llama-cpp.override {
      cudaSupport = true;
      cudaPackages = pkgs.cudaPackages_12_6;
    })
  ];
}