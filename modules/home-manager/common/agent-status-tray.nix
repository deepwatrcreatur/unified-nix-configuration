{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.agent-status-tray;
  codingAgents = import ../../../lib/coding-agents.nix {
    inherit pkgs inputs;
  };
  trayConfig = {
    refresh_interval_seconds = cfg.refreshIntervalSeconds;
    claude_cache_ttl_seconds = cfg.claudeCacheTtlSeconds;
    agents = map (agent: {
      inherit (agent) id name command;
    }) codingAgents;
  };
  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      pygobject3
      requests
      pyxdg
      dbus-python
    ]
  );
  girPath = lib.makeSearchPath "lib/girepository-1.0" [
    pkgs.glib
    pkgs.gtk3
    pkgs.libayatana-appindicator
  ];
  libraryPath = lib.makeLibraryPath [
    pkgs.glib
    pkgs.gtk3
    pkgs.libayatana-appindicator
  ];
  trayPackage = pkgs.writeShellApplication {
    name = "agent-status-tray";
    runtimeInputs = [
      pythonEnv
      pkgs.bash
      pkgs.coreutils
      pkgs.curl
      pkgs.glib
      pkgs.gtk3
      pkgs.jq
      pkgs.libayatana-appindicator
      pkgs.sqlite
      pkgs.xdg-utils
    ];
    text = ''
      export GI_TYPELIB_PATH="${girPath}''${GI_TYPELIB_PATH:+:$GI_TYPELIB_PATH}"
      export LD_LIBRARY_PATH="${libraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      export AGENT_STATUS_TRAY_CONFIG="${config.xdg.configHome}/agent-status-tray/config.json"
      export AGENT_STATUS_TRAY_CACHE="${config.xdg.cacheHome}/agent-status-tray/status.json"
      exec ${pythonEnv}/bin/python ${../../../pkgs/agent-status-tray/agent_status_tray.py} "$@"
    '';
  };
in
{
  options.services.agent-status-tray = {
    enable = lib.mkEnableOption "StatusNotifier tray for local coding agent quota and login status";

    refreshIntervalSeconds = lib.mkOption {
      type = lib.types.int;
      default = 90;
      description = "How often to refresh agent status.";
    };

    claudeCacheTtlSeconds = lib.mkOption {
      type = lib.types.int;
      default = 60;
      description = "How long Claude quota responses are cached before hitting Anthropic again.";
    };
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    home.packages = [ trayPackage ];

    xdg.configFile."agent-status-tray/config.json".text = builtins.toJSON trayConfig;

    systemd.user.services.agent-status-tray = {
      Unit = {
        Description = "Coding agent status tray";
        After = [ "graphical-session.target" "network-online.target" ];
        Wants = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${trayPackage}/bin/agent-status-tray";
        Restart = "always";
        RestartSec = 10;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
