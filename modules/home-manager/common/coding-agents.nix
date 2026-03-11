{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    claude-code
    claude-monitor
    cursor-cli
    gemini-cli
    github-copilot-cli   
    factory-droid
    inputs.codex-cli-nix.packages.${pkgs.system}.codex
  ];
}
