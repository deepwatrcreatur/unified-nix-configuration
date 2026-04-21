{ config, lib, pkgs, ... }:

let
  cfg = config.services.guacamole-module;
in
{
  options.services.guacamole-module = {
    enable = lib.mkEnableOption "Apache Guacamole with PostgreSQL and OIDC (Authentik) support";

    domain = lib.mkOption {
      type = lib.types.str;
      default = "guacamole.deepwatercreature.com";
      description = "Public domain for Guacamole.";
    };

    dbPasswordFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file containing the PostgreSQL password for guacamole_user (e.g. an agenix secret).";
      example = "/run/agenix/guacamole-db-password";
    };

    oidc = {
      enable = lib.mkEnableOption "OIDC authentication (e.g., via Authentik)";
      issuer = lib.mkOption {
        type = lib.types.str;
        default = "https://authentik.deepwatercreature.com/application/o/guacamole/";
        description = "OIDC Issuer URL.";
      };
      clientId = lib.mkOption {
        type = lib.types.str;
        description = "OIDC Client ID.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Guacamole daemon (guacd)
    services.guacamole-server = {
      enable = true;
      host = "127.0.0.1";
      port = 4822;
    };

    # Guacamole web client (Tomcat). The postgresql-password is injected at
    # runtime by the pre-start script below so it never lands in the Nix store.
    services.guacamole-client = {
      enable = true;
      settings = {
        guacd-hostname = "127.0.0.1";
        guacd-port = 4822;
        postgresql-hostname = "localhost";
        postgresql-port = 5432;
        postgresql-database = "guacamole_db";
        postgresql-username = "guacamole_user";
        # Placeholder — overwritten at runtime by the ExecStartPre script.
        postgresql-password = "";
        extension-priority = "oidc,postgresql";
      } // (lib.optionalAttrs cfg.oidc.enable {
        oidc-issuer = cfg.oidc.issuer;
        oidc-client-id = cfg.oidc.clientId;
        oidc-redirect-uri = "https://${cfg.domain}/";
        oidc-username-claim-type = "preferred_username";
        oidc-groups-claim-type = "groups";
      });
    };

    # Patch the generated guacamole.properties with the runtime password before
    # Tomcat starts. The sed command replaces the placeholder empty value.
    systemd.services.guacamole-client.serviceConfig.ExecStartPre =
      let
        script = pkgs.writeShellScript "guacamole-inject-password" ''
          set -euo pipefail
          PASS=$(cat ${cfg.dbPasswordFile})
          PROPS=/etc/guacamole/guacamole.properties
          sed -i "s|^postgresql-password:.*|postgresql-password: $PASS|" "$PROPS"
        '';
      in
      [ "+${script}" ];

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "guacamole_db" ];
      ensureUsers = [
        {
          name = "guacamole_user";
          ensureDBOwnership = true;
        }
      ];
    };

    networking.firewall.allowedTCPPorts = [ 8080 ];
  };
}
