# modules/home-manager/common/coding-agents.nix
# AI coding agents configuration
# Uses nix-rtk for RTK hooks, llm-agents.nix for packages
{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nix-rtk.homeManagerModules.default
    inputs.qmd.homeModules.default
    ./agent-guards.nix
    ./session-search.nix
  ];

  # Enable destructive command guard for all agents
  programs.agent-guards.enable = lib.mkDefault true;

  # Enable CASS session search
  programs.session-search.enable = lib.mkDefault true;

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
  home.packages =
    (with pkgs.llm-agents; [
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
      inputs.nix-session-search.packages.${pkgs.system}.default
    ])
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      pkgs.bubblewrap
    ];
}
