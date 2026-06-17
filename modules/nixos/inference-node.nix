{ config, lib, options, ... }:
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

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = modelsCfg.enable;
          message = "myModules.inferenceModels.enable must be true when myModules.inferenceNode.enable is true.";
        }
      ];
    })

    (lib.optionalAttrs (options ? tesla-inference) {
      # Ollama wiring – only emit this subtree when the tesla-inference module is available.
      tesla-inference = lib.mkIf (cfg.enable && (lib.elem "ollama" cfg.engine)) {
        enable = true;
        ollama = {
          enable = true;
          modelsPath = cfg.modelsPath;
        };
      };
    })
  ];
}
