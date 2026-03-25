# modules/home-manager/common/coding-agents.nix
# AI coding agents and RTK hook integration
# Packages from numtide/llm-agents.nix, RTK hooks managed locally
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.coding-agents;

  # RTK integration configuration
  rtkIntegrations = {
    claude = [ "--global" "--auto-patch" ];
    codex = [ "--global" "--codex" ];
    gemini = [ "--global" "--gemini" "--auto-patch" ];
    opencode = [ "--global" "--opencode" ];
  };

  enabledIntegrations = lib.filterAttrs (_: v: v.enable) cfg.rtk.integrations;
  enabledNames = lib.attrNames enabledIntegrations;

  desiredRtkState = builtins.toJSON {
    enabled = enabledNames;
  };

  shellArgs = args: lib.concatStringsSep " " (map lib.escapeShellArg args);
in
{
  options.programs.coding-agents = {
    enable = lib.mkEnableOption "AI coding agent CLI tools" // { default = true; };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Additional packages alongside the coding agent toolset";
    };

    rtk = {
      enable = lib.mkEnableOption "RTK (Rust Token Killer) for token optimization" // { default = true; };

      integrations = {
        claude.enable = lib.mkEnableOption "RTK Claude Code hook" // { default = true; };
        codex.enable = lib.mkEnableOption "RTK Codex hook";
        gemini.enable = lib.mkEnableOption "RTK Gemini CLI hook";
        opencode.enable = lib.mkEnableOption "RTK OpenCode hook";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs.llm-agents; [
      # Core agents from llm-agents overlay
      rtk
      claude-code
      opencode
      codex
      gemini-cli

      # Utilities
      ccusage  # Claude Code usage tracking
    ] ++ cfg.extraPackages;

    # RTK hook installation/management
    home.activation.rtkIntegrations = lib.mkIf cfg.rtk.enable (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        state_dir="${config.xdg.stateHome}/coding-agents"
        state_file="$state_dir/rtk-integrations.json"
        desired_state=${lib.escapeShellArg desiredRtkState}
        previous_state=""

        if [ -f "$state_file" ]; then
          previous_state="$(cat "$state_file")"
        fi

        if [ "$previous_state" != "$desired_state" ]; then
          mkdir -p "$state_dir"

          # Uninstall previous integrations
          ${lib.concatMapStringsSep "\n" (name: ''
            case "$previous_state" in
              *'"${name}"'*)
                ${lib.getExe pkgs.llm-agents.rtk} init ${shellArgs (rtkIntegrations.${name} ++ [ "--uninstall" ])} 2>/dev/null || true
                ;;
            esac
          '') (lib.attrNames rtkIntegrations)}

          # Install current integrations
          ${lib.concatMapStringsSep "\n" (name: ''
            ${lib.getExe pkgs.llm-agents.rtk} init ${shellArgs rtkIntegrations.${name}}
          '') enabledNames}

          printf '%s' "$desired_state" > "$state_file"
        fi
      ''
    );
  };
}
