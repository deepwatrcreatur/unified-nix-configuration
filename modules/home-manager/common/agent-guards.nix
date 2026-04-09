# modules/home-manager/common/agent-guards.nix
# Destructive command guard for AI coding agents
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.agent-guards;
  guardScript = ../../../scripts/check-destructive.sh;
in
{
  options.programs.agent-guards = {
    enable = lib.mkEnableOption "destructive command guard for AI agents";
    
    # Allow per-user/host overrides of what is considered destructive if needed
    extraSafeTargets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional directory patterns that are safe for recursive delete";
    };
  };

  config = lib.mkIf cfg.enable {
    # 1. Install the guard script to the user profile
    home.packages = [
      (pkgs.writeShellScriptBin "agent-guard" ''
        ${builtins.readFile guardScript}
      '')
    ];

    # 2. Configure Claude Code skill for always-on protection
    # We do this by creating a skill in ~/.claude/skills/repo-guard
    home.activation.setupClaudeRepoGuard = lib.hm.dag.entryAfter ["writeBoundary"] ''
      SKILL_DIR="$HOME/.claude/skills/repo-guard"
      $DRY_RUN_CMD mkdir -p "$SKILL_DIR"
      
      $DRY_RUN_CMD cat > "$SKILL_DIR/SKILL.md" <<EOF
---
name: repo-guard
version: 1.0.0
description: "ALWAYS-ON: Repo-wide destructive command guard. Warns before executing rm -rf, force-push, etc."
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "agent-guard --json"
          statusMessage: "Checking for destructive commands..."
---
# Repo Guard

This skill is automatically installed to provide repo-wide safety.
It warns before executing destructive commands.
EOF
    '';

    # 3. Configure Gemini CLI hook
    # Gemini CLI looks for ~/.gemini/config.json
    home.file.".gemini/config.json".text = builtins.toJSON {
      hooks = {
        before_tool = "agent-guard --json";
      };
    };
  };
}
