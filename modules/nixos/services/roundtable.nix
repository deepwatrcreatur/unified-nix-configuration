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
    systemd.services.roundtable = {
      description = "Roundtable discussion orchestrator";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
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

              state_home="${stateHome}"
              mix_home="$state_home/mix"
              deps_path="$state_home/deps"
              build_root="$state_home/build"
              source_dir="$(${pkgs.gnused}/bin/sed -n 's|^cd ||p' ${cfg.package}/bin/roundtable-web)"

              mkdir -p ${stateHome}
              mkdir -p "$mix_home" "$deps_path" "$build_root"

              if [ -f "$CREDENTIALS_DIRECTORY/secret_key_base" ]; then
                export SECRET_KEY_BASE="$(cat "$CREDENTIALS_DIRECTORY/secret_key_base")"
              elif [ -f "${stateHome}/secret_key_base" ]; then
                export SECRET_KEY_BASE="$(cat "${stateHome}/secret_key_base")"
              else
                ${pkgs.openssl}/bin/openssl rand -hex 32 > "${stateHome}/secret_key_base"
                chmod 600 "${stateHome}/secret_key_base"
                export SECRET_KEY_BASE="$(cat "${stateHome}/secret_key_base")"
              fi

              if [ -f "$CREDENTIALS_DIRECTORY/github_token" ]; then
                export GH_TOKEN="$(cat "$CREDENTIALS_DIRECTORY/github_token")"
              fi
              
              if [ -f "$CREDENTIALS_DIRECTORY/anthropic_api_key" ]; then
                export ANTHROPIC_API_KEY="$(cat "$CREDENTIALS_DIRECTORY/anthropic_api_key")"
              fi
              if [ -f "$CREDENTIALS_DIRECTORY/openai_api_key" ]; then
                export OPENAI_API_KEY="$(cat "$CREDENTIALS_DIRECTORY/openai_api_key")"
              fi
              if [ -f "$CREDENTIALS_DIRECTORY/gemini_api_key" ]; then
                export GEMINI_API_KEY="$(cat "$CREDENTIALS_DIRECTORY/gemini_api_key")"
              fi
              if [ -f "$CREDENTIALS_DIRECTORY/deepseek_api_key" ]; then
                export DEEPSEEK_API_KEY="$(cat "$CREDENTIALS_DIRECTORY/deepseek_api_key")"
              fi

              export HOME="$state_home"
              export XDG_STATE_HOME="$state_home"
              export MIX_HOME="$mix_home"
              export HEX_HOME="$mix_home/hex"
              export MIX_ARCHIVES="$mix_home/archives"
              export MIX_DEPS_PATH="$deps_path"
              export MIX_BUILD_ROOT="$build_root"

              cd "$source_dir"

              mix local.hex --force >/dev/null 2>&1 || true
              mix local.rebar --force >/dev/null 2>&1 || true
              mix deps.get >/dev/null
              mix compile --force >/dev/null

              exec mix run --no-halt
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
