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

    # Factory.ai Droid (installed via the upstream install script)
    (writeShellScriptBin "droid" ''
      set -euo pipefail
      exec "$HOME/.factory/bin/droid" "$@"
    '')
  ];
in
{
  home.packages = basePackages;
}
