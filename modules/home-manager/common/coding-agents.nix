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
      if [ ! -x "$HOME/.factory/bin/droid" ]; then
        echo "Factory droid not installed at $HOME/.factory/bin/droid" >&2
        echo "Install it with: curl -fsSL https://app.factory.ai/cli | sh" >&2
        exit 1
      fi
      exec "$HOME/.factory/bin/droid" "$@"
    '')
  ];
in
{
  home.packages = basePackages;
}
