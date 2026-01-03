{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.inference.ollama;
  gpuCfg = config.inference.gpu;
in
{
  options.inference.ollama = {
    enable = lib.mkEnableOption "Ollama service with GPU acceleration for inference";

    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Host address for Ollama service";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 11434;
      description = "Port for Ollama service";
    };

    modelsPath = lib.mkOption {
      type = lib.types.str;
      default = "/models/ollama";
      description = "Path where Ollama models are stored";
    };

    acceleration = lib.mkOption {
      type = lib.types.enum [ "auto" "cuda" "rocm" "cpu" ];
      default = "auto"; # Let Ollama auto-detect to avoid circular dependency
      description = "Hardware acceleration backend for Ollama";
    };

    customBuild = {
      enable = lib.mkEnableOption "Custom Ollama build with specific CUDA architectures";

      cudaArchitectures = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "61" "70" "75" "80" "86" "89" "90" ]; # Include Tesla P40 (6.1) by default
        description = "CUDA compute capabilities to compile for";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure GPU infrastructure is enabled if using CUDA
    inference.gpu = lib.mkIf (cfg.acceleration == "cuda") {
      enable = lib.mkDefault true;
      nvidia.enable = lib.mkDefault true;
      cuda.enable = lib.mkDefault true;
    };

    # Custom overlay for specific CUDA architectures
    nixpkgs.overlays = lib.optionals (cfg.customBuild.enable && cfg.acceleration == "cuda") [
      (final: prev: {
        ollama = prev.ollama.overrideAttrs (old: {
          # Use specified CUDA architectures
          cmakeFlags = (old.cmakeFlags or [ ]) ++ [
            "-DGGML_CUDA_ARCHITECTURES=${lib.concatStringsSep ";" cfg.customBuild.cudaArchitectures}"
          ];

          # Ensure CUDA support with dependencies from GPU infrastructure
          buildInputs = (old.buildInputs or [ ]) ++ [
            gpuCfg.cuda.package.cuda_nvcc
            gpuCfg.cuda.package.cuda_cudart
            gpuCfg.cuda.package.libcublas
            gpuCfg.cuda.package.libcusparse
            gpuCfg.cuda.package.libcurand
          ];

          # Set CUDA compilation environment
          preConfigure = (old.preConfigure or "") + ''
            export CUDA_PATH=${gpuCfg.cuda.package.cudatoolkit}
            export CUDACXX=${gpuCfg.cuda.package.cuda_nvcc}/bin/nvcc
          '';
        });
      })
    ];

    # Don't use the nixpkgs ollama service module - manage our own service
    # This allows us to completely control the startup behavior
    services.ollama.enable = false;

    # Manually define the ollama service with proper startup ordering
    systemd.services.ollama = {
      description = "Server for local large language models";
      enable = true;
      wantedBy = [ ];  # Don't auto-start via normal boot
      after = [ "network.target" "systemd-tmpfiles-setup.service" ];
      serviceConfig = {
        Type = "notify";
        ExecStart = "${pkgs.ollama}/bin/ollama serve";
        User = "ollama";
        Group = "ollama";
        WorkingDirectory = cfg.modelsPath;
        ReadWritePaths = [ cfg.modelsPath ];
        Restart = "always";
        RestartSec = 3;
        StandardOutput = "journal";
        StandardError = "journal";
        # Prevent service from failing hard if modelspath doesn't exist yet
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${cfg.modelsPath}/models/blobs";
      };
      environment = {
        OLLAMA_HOST = "${cfg.host}:${toString cfg.port}";
        OLLAMA_MODELS = "${cfg.modelsPath}/models";
        HOME = cfg.modelsPath;
      };
    };

    # Create a timer to start ollama after everything is ready
    systemd.timers.ollama-startup = {
      description = "Start ollama service after system boot";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "3s";
        Unit = "ollama.service";
        Persistent = true;
      };
    };

    # Ensure models directory exists with correct permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.modelsPath} 0755 ollama ollama -"
      "d ${cfg.modelsPath}/models 0755 ollama ollama -"
      # Also ensure /var/lib/ollama and subdirectories exist since ollama internally tries to create them
      # even though we override environment variables
      "d /var/lib/ollama 0755 ollama ollama -"
      "d /var/lib/ollama/models 0755 ollama ollama -"
      "d /var/lib/ollama/models/blobs 0755 ollama ollama -"
    ];

    # Add ollama user to system if not already present
    users.users.ollama = {
      isSystemUser = true;
      group = "ollama";
      home = cfg.modelsPath;
    };
    users.groups.ollama = {};

    # Global environment variables for all users
    environment.variables = {
      OLLAMA_HOST = "${cfg.host}:${toString cfg.port}";
    };
  };
}