# modules/home-manager/common/session-search.nix
# Configuration for Coding Agent Session Search (CASS)
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.programs.session-search;
in
{
  options.programs.session-search = {
    enable = lib.mkEnableOption "Coding Agent Session Search (CASS) integration";
    
    package = lib.mkOption {
      type = lib.types.package;
      default = inputs.nix-session-search.packages.${pkgs.system}.default;
      description = "The CASS package to use.";
    };

    indexInterval = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      description = "How often to re-index agent sessions (systemd calendar format).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    # Configure shell aliases for easier use by agents and humans
    home.shellAliases = {
      "qs" = "cass search --robot"; # Quick Search for agents
      "cs" = "cass";               # CASS TUI for humans
    };

    # Periodically index sessions using a systemd timer
    systemd.user.services.cass-index = {
      Unit = {
        Description = "Index AI coding agent sessions for CASS";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${cfg.package}/bin/cass index --full";
        # Ensure we don't fail if some session directories are missing
        SuccessExitStatus = [ 0 1 ];
      };
    };

    systemd.user.timers.cass-index = {
      Unit = {
        Description = "Periodically index AI coding agent sessions";
      };
      Timer = {
        OnCalendar = cfg.indexInterval;
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };

    # Add documentation for agents in the workspace
    home.file.".cass-guide.md".text = ''
# CASS Session Search Guide for Agents

Past session history from Claude, Codex, Gemini, and other agents is indexed and searchable.

## Usage

- **Search**: `cass search "topic" --robot` (returns machine-readable JSON context)
- **View Session**: `cass view <path> --json`
- **Expand Context**: `cass expand <path> -n <line> -C 5 --json`

Always use the `--robot` or `--json` flags when running `cass` within an automated session to avoid launching the TUI.
'';
  };
}
