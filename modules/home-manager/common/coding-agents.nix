{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Base packages that should always be available
  basePackages = with pkgs; [
    claude-code
    claude-monitor
    cursor-cli
    gemini-cli
    opencode
  ];
in
{
  home.packages = basePackages;
}
