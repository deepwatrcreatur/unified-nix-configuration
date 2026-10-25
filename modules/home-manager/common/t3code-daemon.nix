# modules/home-manager/common/t3code-daemon.nix
# Declarative Home Manager user service for T3 Code Server Daemon
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.t3code;
in
{
  options.services.t3code = {
    enable = lib.mkEnableOption "T3 Code agent harness background server daemon";

    package = lib.mkOption {
      type = lib.types.package;
      default = config.programs.t3code.package or pkgs.t3code;
      defaultText = lib.literalExpression "config.programs.t3code.package";
      description = "The t3code package to use.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3773;
      description = "TCP port on which the T3 Code backend server listens.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "Host / interface to bind (e.g. 127.0.0.1, 0.0.0.0, or Tailnet IP).";
    };

    tailscale = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Expose the T3 Code server over Tailscale Serve HTTPS.";
    };

    tailscalePort = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = null;
      description = "Optional custom port for Tailscale Serve.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.t3";
      defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/.t3"'';
      description = "Base data directory for T3 Code state and userdata.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional command line arguments passed to `t3 serve`.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.desktopEntries.t3code-url-handler = {
      name = "T3 Code (Alpha)";
      exec = "t3code %U";
      terminal = false;
      noDisplay = true;
      mimeType = [
        "x-scheme-handler/t3code"
        "x-scheme-handler/t3code-dev"
      ];
    };

    systemd.user.services.t3code = {
      Unit = {
        Description = "T3 Code Agent Harness Daemon";
        Documentation = [ "https://github.com/pingdotgg/t3code" ];
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "simple";
        WorkingDirectory = config.home.homeDirectory;
        Environment = [
          "T3CODE_HOME=${cfg.dataDir}"
          "T3_BOOT_SERVICE_UNIT=t3code.service"
        ];
        ExecStart = lib.concatStringsSep " " (
          [
            "${cfg.package}/bin/t3"
            "serve"
            "--port"
            (toString cfg.port)
            "--host"
            cfg.host
            "--base-dir"
            cfg.dataDir
          ]
          ++ lib.optional cfg.tailscale "--tailscale-serve"
          ++ lib.optionals (cfg.tailscalePort != null) [
            "--tailscale-serve-port"
            (toString cfg.tailscalePort)
          ]
          ++ cfg.extraArgs
        );
        KillMode = "mixed";
        Restart = "always";
        RestartSec = 5;
        StandardOutput = "journal";
        StandardError = "journal";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
