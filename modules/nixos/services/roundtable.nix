{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.roundtable;
in
{
  options.services.roundtable = {
    enable = lib.mkEnableOption "roundtable discussion orchestrator";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.roundtable-web;
      description = "The roundtable package to use.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 4000;
      description = "The port the roundtable service will listen on.";
    };

    secretKeyBaseFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing SECRET_KEY_BASE.";
    };

    githubTokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing GitHub PAT.";
    };

    anthropicApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional path to file containing Anthropic API key.";
    };

    openaiApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional path to file containing OpenAI API key.";
    };

    geminiApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional path to file containing Gemini API key.";
    };

    deepseekApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional path to file containing DeepSeek API key.";
    };

    exaApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional path to file containing Exa API key.";
    };

    phoenixHost = lib.mkOption {
      type = lib.types.str;
      default = "roundtable.deepwatercreature.com";
      description = "The public hostname for the Phoenix application.";
    };

    oidcIssuerUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Authentik OIDC issuer URL (empty = unauthenticated dev mode).";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "roundtable";
      description = "The name of the state directory under /var/lib.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.roundtable = {
      description = "Roundtable discussion orchestrator";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = with pkgs; [
        dolt
        git
        gh
      ];

      serviceConfig = {
        ExecStart =
          let
            startScript = pkgs.writeShellScript "roundtable-start" ''
              export SECRET_KEY_BASE=$(cat $CREDENTIALS_DIRECTORY/secret_key_base)
              export GH_TOKEN=$(cat $CREDENTIALS_DIRECTORY/github_token)
              
              if [ -f $CREDENTIALS_DIRECTORY/anthropic_api_key ]; then
                export ANTHROPIC_API_KEY=$(cat $CREDENTIALS_DIRECTORY/anthropic_api_key)
              fi
              if [ -f $CREDENTIALS_DIRECTORY/openai_api_key ]; then
                export OPENAI_API_KEY=$(cat $CREDENTIALS_DIRECTORY/openai_api_key)
              fi
              if [ -f $CREDENTIALS_DIRECTORY/gemini_api_key ]; then
                export GEMINI_API_KEY=$(cat $CREDENTIALS_DIRECTORY/gemini_api_key)
              fi
              if [ -f $CREDENTIALS_DIRECTORY/deepseek_api_key ]; then
                export DEEPSEEK_API_KEY=$(cat $CREDENTIALS_DIRECTORY/deepseek_api_key)
              fi
              if [ -f $CREDENTIALS_DIRECTORY/exa_api_key ]; then
                export EXA_API_KEY=$(cat $CREDENTIALS_DIRECTORY/exa_api_key)
              fi

              exec ${cfg.package}/bin/roundtable-web
            '';
          in
          "${startScript}";

        LoadCredential =
          [
            "secret_key_base:${cfg.secretKeyBaseFile}"
            "github_token:${cfg.githubTokenFile}"
          ]
          ++ lib.optional (cfg.anthropicApiKeyFile != null) "anthropic_api_key:${cfg.anthropicApiKeyFile}"
          ++ lib.optional (cfg.openaiApiKeyFile != null) "openai_api_key:${cfg.openaiApiKeyFile}"
          ++ lib.optional (cfg.geminiApiKeyFile != null) "gemini_api_key:${cfg.geminiApiKeyFile}"
          ++ lib.optional (cfg.deepseekApiKeyFile != null) "deepseek_api_key:${cfg.deepseekApiKeyFile}"
          ++ lib.optional (cfg.exaApiKeyFile != null) "exa_api_key:${cfg.exaApiKeyFile}";

        Environment = [
          "PORT=${toString cfg.port}"
          "PHX_HOST=${cfg.phoenixHost}"
          "OIDC_ISSUER_URL=${cfg.oidcIssuerUrl}"
          "ROUNDTABLE_WEB=true"
          "MIX_ENV=prod"
        ];
        DynamicUser = true;
        StateDirectory = cfg.stateDir;
        Restart = "on-failure";
      };
    };
  };
}
