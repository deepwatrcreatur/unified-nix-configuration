{ config, lib, ... }:
let
  cfg = config.myModules.inferenceNode;
  modelsCfg = config.myModules.inferenceModels;
in {
  options.myModules.inferenceNode = {
    enable = lib.mkEnableOption "Turn this NixOS host into an inference node";

    role = lib.mkOption {
      type = lib.types.enum [ "gpu-worker" "controller" ];
      default = "gpu-worker";
      description = "Logical role of this node in the inference cluster.";
    };

    engine = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [ "ollama" "vllm" "llama-cpp" ]);
      default = [ "ollama" ];
      description = "Inference engines to enable on this node.";
    };

    modelsPath = lib.mkOption {
      type = lib.types.str;
      default = modelsCfg.mountPoint or "/srv/models";
      description = "Path where engines should look for models (usually shared storage).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = modelsCfg.enable;
        message = "myModules.inferenceModels.enable must be true when myModules.inferenceNode.enable is true.";
      }
    ];

    # Ollama wiring – assumes tesla-inference module is available on the system.
    tesla-inference = lib.mkIf (lib.elem "ollama" cfg.engine) {
      enable = true;
      ollama = {
        enable = true;
        modelsPath = cfg.modelsPath;
      };
    };

    # Placeholders for future vLLM and llama.cpp modules.
    # We only reserve options here so hosts can already declare intent.
    # Actual service modules can be added later.
  };
}
