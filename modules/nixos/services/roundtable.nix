{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.roundtable;
  stateHome = "/var/lib/${cfg.stateDir}";
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
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional path to file containing SECRET_KEY_BASE.";
    };

    githubTokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional path to file containing GitHub PAT.";
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
    networking.firewall.allowedTCPPorts = [ cfg.port ];

    systemd.services.roundtable = {
      description = "Roundtable discussion orchestrator";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = with pkgs; [
        bash
        coreutils
        curl
        dolt
        elixir
        beam.packages.erlang.erlang
        git
        gh
        jujutsu
        openssl
      ];

      serviceConfig = {
        ExecStart =
          let
            startScript = pkgs.writeShellScript "roundtable-start" ''
              set -eu

              mkdir -p "${stateHome}/state"
              credential_dir="''${CREDENTIALS_DIRECTORY:-}"

              if [ -n "$credential_dir" ] && [ -f "$credential_dir/secret_key_base" ]; then
                export SECRET_KEY_BASE="$(cat "$credential_dir/secret_key_base")"
              elif [ -f "${stateHome}/secret_key_base" ]; then
                export SECRET_KEY_BASE="$(cat "${stateHome}/secret_key_base")"
              else
                ${pkgs.openssl}/bin/openssl rand -hex 32 > "${stateHome}/secret_key_base"
                chmod 600 "${stateHome}/secret_key_base"
                export SECRET_KEY_BASE="$(cat "${stateHome}/secret_key_base")"
              fi

              if [ -n "$credential_dir" ] && [ -f "$credential_dir/github_token" ]; then
                export GH_TOKEN="$(cat "$credential_dir/github_token")"
              fi

              if [ -n "$credential_dir" ] && [ -f "$credential_dir/anthropic_api_key" ]; then
                export ANTHROPIC_API_KEY="$(cat "$credential_dir/anthropic_api_key")"
              fi
              if [ -n "$credential_dir" ] && [ -f "$credential_dir/openai_api_key" ]; then
                export OPENAI_API_KEY="$(cat "$credential_dir/openai_api_key")"
              fi
              if [ -n "$credential_dir" ] && [ -f "$credential_dir/gemini_api_key" ]; then
                export GEMINI_API_KEY="$(cat "$credential_dir/gemini_api_key")"
              fi
              if [ -n "$credential_dir" ] && [ -f "$credential_dir/deepseek_api_key" ]; then
                export DEEPSEEK_API_KEY="$(cat "$credential_dir/deepseek_api_key")"
              fi

              exec ${cfg.package}/bin/roundtable-web
            '';
          in
          "${startScript}";

        LoadCredential =
          lib.optional (cfg.secretKeyBaseFile != null) "secret_key_base:${cfg.secretKeyBaseFile}"
          ++ lib.optional (cfg.githubTokenFile != null) "github_token:${cfg.githubTokenFile}"
          ++ lib.optional (cfg.anthropicApiKeyFile != null) "anthropic_api_key:${cfg.anthropicApiKeyFile}"
          ++ lib.optional (cfg.openaiApiKeyFile != null) "openai_api_key:${cfg.openaiApiKeyFile}"
          ++ lib.optional (cfg.geminiApiKeyFile != null) "gemini_api_key:${cfg.geminiApiKeyFile}"
          ++ lib.optional (cfg.deepseekApiKeyFile != null) "deepseek_api_key:${cfg.deepseekApiKeyFile}";

        Environment = [
          "PORT=${toString cfg.port}"
          "PHX_HOST=${cfg.phoenixHost}"
          "HOST=${cfg.phoenixHost}"
          "HOME=${stateHome}"
          "XDG_STATE_HOME=${stateHome}"
          "ROUNDTABLE_STATE_DIR=${stateHome}/state"
          "ROUNDTABLE_BRIEF=docs/design/BRIEF.md"
          "OIDC_ISSUER_URL=${cfg.oidcIssuerUrl}"
          "ROUNDTABLE_WEB=true"
          "MIX_ENV=prod"
        ];
        DynamicUser = true;
        StateDirectory = cfg.stateDir;
        WorkingDirectory = stateHome;
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
