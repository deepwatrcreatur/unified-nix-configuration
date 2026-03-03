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
    opencode # Provided by overlay - fetches latest from GitHub releases
    factory-droid
  ];
in
{
  home.packages = basePackages;
}
