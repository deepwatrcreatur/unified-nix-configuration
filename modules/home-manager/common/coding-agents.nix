# modules/home-manager/common/coding-agents.nix
# AI coding agents configuration
# Uses nix-rtk for RTK hooks, llm-agents.nix for packages
{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.coding-agents;
in
{
  imports = [
    inputs.nix-rtk.homeManagerModules.default
    inputs.qmd.homeModules.default
    ./agent-guards.nix
    ./cass-session-search.nix
  ];

  options.programs.coding-agents.enable = lib.mkEnableOption "AI coding agent packages and integrations" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    programs.agent-guards.enable = lib.mkDefault true;
    programs.cass-session-search.enable = lib.mkDefault true;

    # Enable RTK hooks with Claude enabled by default
    programs.rtk-hooks = {
      enable = lib.mkDefault true;
      integrations = {
        claude.enable = lib.mkDefault true;
      };
    };

    programs.qmd = {
      enable = lib.mkDefault false;
      package = lib.mkDefault pkgs.qmd;
    };

    # Install coding agent packages from llm-agents overlay
    home.packages = with pkgs.llm-agents; [
      # Core agents
      rtk
      claude-code
      opencode
      codex
      gemini-cli
      amp
      copilot-cli
      cursor-agent
      forge
      goose-cli
      kilocode-cli
      pi
      crush
      agent-deck
      workmux

      # Usage trackers
      ccusage
      ccusage-amp
      ccusage-codex
      ccusage-opencode

      # Utilities
      ccstatusline
    ];
  };
}
