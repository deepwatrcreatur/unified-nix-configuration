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
  imports = [ inputs.nix-rtk.homeManagerModules.default ];

  # Enable RTK hooks with Claude enabled by default
  programs.rtk-hooks = {
    enable = lib.mkDefault true;
    integrations = {
      claude.enable = lib.mkDefault true;
    };
  };

  # Install coding agent packages from llm-agents overlay
  home.packages = with pkgs.llm-agents; [
    rtk
    claude-code
    opencode
    codex
    gemini-cli
    ccusage
  ];
}
