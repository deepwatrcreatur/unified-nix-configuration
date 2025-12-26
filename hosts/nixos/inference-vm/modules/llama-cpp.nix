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
    enable = lib.mkEnableOption "llama.cpp inference server with GPU acceleration";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.llama-cpp;
      description = "llama.cpp package to use";
    };

    server = {
      enable = lib.mkEnableOption "llama.cpp server daemon";

      host = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
        description = "Host address for llama.cpp server";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
        description = "Port for llama.cpp server";
      };

      modelsPath = lib.mkOption {
        type = lib.types.str;
        default = "/models/llama-cpp";
        description = "Path where llama.cpp models are stored";
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional arguments to pass to llama.cpp server";
      };
    };

    acceleration = lib.mkOption {
      type = lib.types.enum [ "auto" "cuda" "rocm" "vulkan" "cpu" ];
      default = if gpuCfg.cuda.enable then "cuda" else "auto";
      description = "Hardware acceleration backend for llama.cpp";
    };

    customBuild = {
      enable = lib.mkEnableOption "Custom llama.cpp build with specific acceleration support";

      cudaSupport = lib.mkOption {
        type = lib.types.bool;
        default = gpuCfg.cuda.enable;
        description = "Build with CUDA support";
      };

      rocmSupport = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Build with ROCm support";
      };

      vulkanSupport = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Build with Vulkan support";
      };

      openblasSupport = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Build with OpenBLAS support for CPU optimization";
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

    # Custom package build with specific acceleration support
    nixpkgs.overlays = lib.optionals cfg.customBuild.enable [
      (final: prev: {
        llama-cpp = prev.llama-cpp.override {
          cudaSupport = cfg.customBuild.cudaSupport;
          rocmSupport = cfg.customBuild.rocmSupport;
          vulkanSupport = cfg.customBuild.vulkanSupport;
          openblasSupport = cfg.customBuild.openblasSupport;
        };
      })
    ];

    # Add llama.cpp to system packages
    environment.systemPackages = [ cfg.package ];

    # llama.cpp server service
    systemd.services.llama-cpp-server = lib.mkIf cfg.server.enable {
      description = "llama.cpp inference server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        User = "llama-cpp";
        Group = "llama-cpp";
        WorkingDirectory = cfg.server.modelsPath;
        ExecStart = ''
          ${cfg.package}/bin/llama-server \
            --host ${cfg.server.host} \
            --port ${toString cfg.server.port} \
            --models-path ${cfg.server.modelsPath} \
            ${lib.concatStringsSep " " cfg.server.extraArgs}
        '';
        Restart = "always";
        RestartSec = 5;

        # Security settings
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ cfg.server.modelsPath ];
        PrivateTmp = true;
        PrivateDevices = lib.mkIf (cfg.acceleration == "cpu") true;

        # Allow GPU access when using acceleration
        DeviceAllow = lib.optionals (cfg.acceleration != "cpu") [
          "/dev/nvidia*"
          "/dev/dri/*"
        ];
      };

      environment = lib.mkMerge [
        (lib.mkIf (cfg.acceleration == "cuda") {
          CUDA_VISIBLE_DEVICES = "all";
          LLAMA_CUDA = "1";
        })
      ];
    };

    # User and group for llama.cpp service
    users.users.llama-cpp = lib.mkIf cfg.server.enable {
      isSystemUser = true;
      group = "llama-cpp";
      home = cfg.server.modelsPath;
    };
    users.groups.llama-cpp = lib.mkIf cfg.server.enable {};

    # Ensure models directory exists
    systemd.tmpfiles.rules = lib.optionals cfg.server.enable [
      "d ${cfg.server.modelsPath} 0755 llama-cpp llama-cpp -"
    ];

    # Global environment variables
    environment.variables = lib.mkIf cfg.server.enable {
      LLAMA_CPP_SERVER = "${cfg.server.host}:${toString cfg.server.port}";
    };

    # Firewall configuration
    networking.firewall.allowedTCPPorts = lib.optionals cfg.server.enable [
      cfg.server.port
    ];
  };
}