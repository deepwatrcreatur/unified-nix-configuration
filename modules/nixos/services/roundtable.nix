{ config, lib, pkgs, ... }:

let
  cfg = config.services.roundtable;
  envFilePath = "/run/${cfg.runtimeDir}/roundtable.env";
  startScript = pkgs.writeShellScript "roundtable-web-start" ''
    set -euo pipefail
    set -a
    . ${lib.escapeShellArg envFilePath}
    set +a
    exec ${cfg.package}/bin/roundtable-web
  '';
in
{
  options.services.roundtable = {
    enable = lib.mkEnableOption "roundtable discussion orchestrator";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.roundtable-web;
      description = "The roundtable package wrapper to execute.";
    };

    workingDirectory = lib.mkOption {
      type = lib.types.str;
      description = "Checkout path containing the Roundtable mix project.";
      example = "/home/deepwatrcreatur/flakes/agent-roundtable/roundtable";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "deepwatrcreatur";
      description = "User that runs the service.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Primary group for the service user.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 4000;
      description = "The port the roundtable service will listen on.";
    };

    secretKeyBaseFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to file containing the raw Phoenix SECRET_KEY_BASE.";
    };

    githubTokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to file containing the raw GitHub PAT used as GH_TOKEN and GITHUB_SERVICE_PAT.";
    };

    phoenixHost = lib.mkOption {
      type = lib.types.str;
      default = "roundtable.deepwatercreature.com";
      description = "Public hostname for the Phoenix endpoint.";
    };

    oidcIssuerUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "OIDC issuer URL; empty disables OIDC.";
    };

    oidcClientIdFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional path to a file containing the OIDC client ID.";
    };

    oidcClientSecretFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional path to a file containing the OIDC client secret.";
    };

    discussionRepo = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Optional owner/repo slug shown in the dashboard.";
    };

    discussionBriefPath = lib.mkOption {
      type = lib.types.str;
      default = "BRIEF.md";
      description = "Path to the brief file relative to the discussion repo checkout.";
    };

    runtimeDir = lib.mkOption {
      type = lib.types.str;
      default = "roundtable";
      description = "Runtime directory used for generated environment files.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.roundtable = {
      description = "Roundtable discussion orchestrator";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      preStart =
        let
          maybeCat =
            path:
            if path == null then
              ""
            else
              ''cat ${lib.escapeShellArg path}'';
        in
        ''
          set -euo pipefail

          install -d -m 0750 "$RUNTIME_DIRECTORY"
          env_file="$RUNTIME_DIRECTORY/roundtable.env"

          secret_key_base="$(tr -d '\n' < ${lib.escapeShellArg cfg.secretKeyBaseFile})"
          test -n "$secret_key_base"

          {
            printf 'SECRET_KEY_BASE=%s\n' "$secret_key_base"
            printf 'PORT=%s\n' ${lib.escapeShellArg (toString cfg.port)}
            printf 'HOST=%s\n' ${lib.escapeShellArg cfg.phoenixHost}
            printf 'PHX_HOST=%s\n' ${lib.escapeShellArg cfg.phoenixHost}
            printf 'ROUNDTABLE_WEB=true\n'
            printf 'MIX_ENV=prod\n'
            printf 'ROUNDTABLE_REPO=%s\n' ${lib.escapeShellArg cfg.discussionRepo}
            printf 'ROUNDTABLE_BRIEF=%s\n' ${lib.escapeShellArg cfg.discussionBriefPath}
          } > "$env_file"

          ${lib.optionalString (cfg.githubTokenFile != null) ''
            github_token="$(tr -d '\n' < ${lib.escapeShellArg cfg.githubTokenFile})"
            if [ -n "$github_token" ]; then
              {
                printf 'GH_TOKEN=%s\n' "$github_token"
                printf 'GITHUB_SERVICE_PAT=%s\n' "$github_token"
              } >> "$env_file"
            fi
          ''}

          ${lib.optionalString (cfg.oidcIssuerUrl != "") ''
            printf 'OIDC_ISSUER_URL=%s\n' ${lib.escapeShellArg cfg.oidcIssuerUrl} >> "$env_file"
          ''}

          ${lib.optionalString (cfg.oidcClientIdFile != null) ''
            oidc_client_id="$(tr -d '\n' < ${lib.escapeShellArg cfg.oidcClientIdFile})"
            if [ -n "$oidc_client_id" ]; then
              printf 'OIDC_CLIENT_ID=%s\n' "$oidc_client_id" >> "$env_file"
            fi
          ''}

          ${lib.optionalString (cfg.oidcClientSecretFile != null) ''
            oidc_client_secret="$(tr -d '\n' < ${lib.escapeShellArg cfg.oidcClientSecretFile})"
            if [ -n "$oidc_client_secret" ]; then
              printf 'OIDC_CLIENT_SECRET=%s\n' "$oidc_client_secret" >> "$env_file"
            fi
          ''}
        '';

      serviceConfig = {
        ExecStart = startScript;
        WorkingDirectory = cfg.workingDirectory;
        RuntimeDirectory = cfg.runtimeDir;
        User = cfg.user;
        Group = cfg.group;
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
