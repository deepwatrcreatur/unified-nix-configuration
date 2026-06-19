# modules/home-manager/common/agent-guards.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.programs.agent-guards;
  jq = lib.getExe pkgs.jq;
  guardPackage = pkgs.writeShellApplication {
    name = "agent-guard";
    runtimeInputs = [ pkgs.jq ];
    text = builtins.readFile ../../../scripts/check-destructive.sh;
  };
  guardCommand = "${lib.getExe guardPackage} --json";

  claudeEnabled =
    config.programs.rtk-hooks.enable
    && config.programs.rtk-hooks.integrations.claude.enable;
  geminiEnabled =
    config.programs.rtk-hooks.enable
    && config.programs.rtk-hooks.integrations.gemini.enable;
in
{
  options.programs.agent-guards = {
    enable = lib.mkEnableOption "repo-managed destructive command guard for coding agents";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ guardPackage ];

    home.activation.agentGuards = lib.hm.dag.entryAfter [ "rtkHooks" ] ''
      ensure_parent_dir() {
        local path="$1"
        $DRY_RUN_CMD mkdir -p "$(dirname "$path")"
      }

      ensure_json_file() {
        local path="$1"
        local initial_json="$2"
        if [ ! -f "$path" ]; then
          ensure_parent_dir "$path"
          printf '%s\n' "$initial_json" > "$path"
        fi
      }

      patch_json() {
        local path="$1"
        local filter="$2"
        local tmp
        tmp="$(mktemp)"
        ${jq} --arg command ${lib.escapeShellArg guardCommand} "$filter" "$path" > "$tmp"
        if ! cmp -s "$tmp" "$path"; then
          ensure_parent_dir "$path"
          $DRY_RUN_CMD mv "$tmp" "$path"
        else
          rm -f "$tmp"
        fi
      }

      ${lib.optionalString claudeEnabled ''
        ensure_json_file "$HOME/.claude/settings.json" '{}'
        patch_json "$HOME/.claude/settings.json" '
          .hooks = (.hooks // {}) |
          .hooks.PreToolUse = (
            (.hooks.PreToolUse // []) as $entries |
            if any($entries[]?; .matcher == "Bash") then
              [
                $entries[] |
                if .matcher == "Bash" then
                  .hooks = (
                    [{"type":"command","command":$command}] +
                    [(.hooks // [])[] | select(.command != $command)]
                  )
                else
                  .
                end
              ]
            else
              $entries + [{
                "matcher": "Bash",
                "hooks": [{ "type": "command", "command": $command }]
              }]
            end
          )
        '
      ''}

      ${lib.optionalString geminiEnabled ''
        ensure_json_file "$HOME/.gemini/settings.json" '{}'
        patch_json "$HOME/.gemini/settings.json" '
          .hooks = (.hooks // {}) |
          .hooks.BeforeTool = (
            (.hooks.BeforeTool // []) as $entries |
            if any($entries[]?; .matcher == "run_shell_command") then
              [
                $entries[] |
                if .matcher == "run_shell_command" then
                  .hooks = (
                    [{"type":"command","command":$command}] +
                    [(.hooks // [])[] | select(.command != $command)]
                  )
                else
                  .
                end
              ]
            else
              $entries + [{
                "matcher": "run_shell_command",
                "hooks": [{ "type": "command", "command": $command }]
              }]
            end
          )
        '
      ''}
    '';
  };
}
