{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../..
  ];

  boot.growPartition = true;

  swapDevices = [
    {
      device = "/swapfile";
      size = 16384;
    }
  ];

  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  boot.kernel.sysctl."vm.overcommit_memory" = 1;

  nix.settings = {
    max-jobs = lib.mkForce 1;
    cores = lib.mkForce 1;
  };

  networking.hostName = "inference1";

  # Custom ollama with CUDA using official binary
  services.ollama = {
    enable = true;
    package = pkgs.stdenv.mkDerivation rec {
      pname = "ollama";
      version = "0.12.11";

      src = pkgs.fetchurl {
        url = "https://github.com/ollama/ollama/releases/download/v${version}/ollama-linux-amd64.tgz";
        sha256 = "sha256-+xQOpCQ3BtAIewEIQY7lxvdO3Ov18U4vKJuONr0wPQ8=";
      };

      sourceRoot = ".";

      nativeBuildInputs = with pkgs; [
        autoPatchelfHook
        patchelf
      ];
      buildInputs = with pkgs; [ stdenv.cc.cc ];

      autoPatchelfIgnoreMissingDeps = [
        "libgcc_s.so.1"
        "libcuda.so.1"
      ];

      installPhase = ''
        mkdir -p $out/bin $out/lib
        cp bin/ollama $out/bin/ollama
        cp -r lib/* $out/lib/

        # Set RPATH to include bundled CUDA libraries
        patchelf --set-rpath "\$ORIGIN/../lib/ollama/cuda_v12:\$ORIGIN/../lib/ollama/cuda_v13:\$ORIGIN/..:$ORIGIN" $out/bin/ollama
      '';

      meta.mainProgram = "ollama";
    };

    host = "0.0.0.0";
    port = 11434;
    environmentVariables = {
      CUDA_VISIBLE_DEVICES = "0";
      OLLAMA_GPU_OVERHEAD = "0";
      LD_LIBRARY_PATH = "/run/opengl-driver/lib";
    };
  };

  users.users.ollama = {
    isSystemUser = true;
    group = "ollama";
    home = "/models/ollama";
  };
  users.groups.ollama = { };

  systemd.services.ollama = {
    environment = {
      OLLAMA_MODELS = lib.mkForce "/models/ollama/models";
      HOME = lib.mkForce "/models/ollama";
    };
    serviceConfig = {
      StateDirectory = lib.mkForce "";
      DynamicUser = lib.mkForce false;
      ReadWritePaths = lib.mkForce [ "/models/ollama" ];
      WorkingDirectory = lib.mkForce "/models/ollama";
      # Allow access to the actual GPU device
      DeviceAllow = [ "/dev/nvidia0" ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /models/ollama 0755 root root -"
    "d /models/ollama/.ollama 0700 ollama ollama -"
    "d /models/ollama/models 0755 ollama ollama -"
    "d /models/ollama/models/blobs 0755 ollama ollama -"
    "d /models/ollama/models/manifests 0755 ollama ollama -"
  ];
}
