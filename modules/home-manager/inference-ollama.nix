{
  config,
  lib,
  ...
}:

let
  cfg = config.programs.inference-ollama;
in
{
  options.programs.inference-ollama = {
    enable = lib.mkEnableOption "Ollama-related shell aliases and environment variables for inference work";

    isRoot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this is the root user (affects available aliases)";
    };

    ollamaHost = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0:11434";
      description = "Ollama host and port";
    };

    modelsPath = lib.mkOption {
      type = lib.types.str;
      default = "/models/ollama";
      description = "Path where Ollama models are stored";
    };
  };

  config = lib.mkIf cfg.enable {
    # Shell aliases for regular users
    programs.nushell.shellAliases = lib.mkMerge [
      # Common aliases for all users
      {
        ollama-status = "systemctl status ollama";
        ollama-logs = lib.mkIf (!cfg.isRoot) "journalctl -u ollama -f";
        models = "ls -la ${cfg.modelsPath}/models/";
      }

      # Root-specific aliases
      (lib.mkIf cfg.isRoot {
        ollama-restart = "systemctl restart ollama";
        ollama-logs = "journalctl -u ollama -n 50";
        models-space = "df -h ${cfg.modelsPath}";
        inference-services = "systemctl list-units --type=service | grep -E 'ollama|nvidia'";
      })
    ];

    # Environment variables
    home.sessionVariables = {
      OLLAMA_HOST = cfg.ollamaHost;
    };
  };
}