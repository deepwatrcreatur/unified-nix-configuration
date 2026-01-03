{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.inference.llama-cpp;
  gpuCfg = config.inference.gpu;
in
{
  options.inference.llama-cpp = {
    enable = lib.mkEnableOption "llama.cpp inference framework with optional CUDA support";

    server = {
      enable = lib.mkEnableOption "llama.cpp HTTP server";

      port = lib.mkOption {
        type = lib.types.port;
        default = 8000;
        description = "Port for llama.cpp HTTP server";
      };

      modelPath = lib.mkOption {
        type = lib.types.str;
        default = "/models/llama-cpp";
        description = "Path to llama.cpp models directory";
      };
    };

    customBuild = {
      enable = lib.mkEnableOption "Custom llama.cpp build with CUDA support";

      cudaSupport = lib.mkEnableOption "Build llama.cpp with CUDA acceleration";

      cudaArchitectures = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "61" ]; # Tesla P40
        description = "CUDA compute capabilities to compile for";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Only configure if GPU infrastructure is available
    assertions = [
      {
        assertion = !cfg.customBuild.cudaSupport || gpuCfg.cuda.enable;
        message = "llama.cpp CUDA support requires GPU infrastructure to be enabled";
      }
    ];

    # Custom llama.cpp overlay with CUDA support
    nixpkgs.overlays = lib.optionals (cfg.customBuild.enable && cfg.customBuild.cudaSupport) [
      (final: prev: {
        llama-cpp = prev.llama-cpp.overrideAttrs (old: {
          # Enable CUDA compute capabilities
          cmakeFlags = (old.cmakeFlags or [ ]) ++ [
            "-DLLAMA_CUDA=ON"
            "-DCMAKE_CUDA_ARCHITECTURES=${lib.concatStringsSep ";" cfg.customBuild.cudaArchitectures}"
          ];

          # Add CUDA dependencies
          buildInputs = (old.buildInputs or [ ]) ++ [
            gpuCfg.cuda.package.cuda_nvcc
            gpuCfg.cuda.package.cuda_cudart
            gpuCfg.cuda.package.libcublas
          ];

          # Set CUDA environment
          preConfigure = (old.preConfigure or "") + ''
            export CUDA_PATH=${gpuCfg.cuda.package.cudatoolkit}
            export CUDACXX=${gpuCfg.cuda.package.cuda_nvcc}/bin/nvcc
          '';
        });
      })
    ];

    # llama.cpp server service configuration
    systemd.services.llama-cpp-server = lib.mkIf cfg.server.enable {
      description = "llama.cpp HTTP inference server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.llama-cpp}/bin/server -m ${cfg.server.modelPath}/model.gguf --port ${toString cfg.server.port}";
        Restart = "on-failure";
        RestartSec = "10s";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    # Model storage directory
    systemd.tmpfiles.rules = lib.optionals cfg.server.enable [
      "d ${cfg.server.modelPath} 0755 root root -"
    ];
  };
}
