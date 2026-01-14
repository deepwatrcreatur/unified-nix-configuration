{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Only create opencode-wrapper if fnox is available
  opencode-wrapper = lib.mkIf (pkgs ? fnox) (pkgs.writeShellScriptBin "opencode" ''
    #!/usr/bin/env bash
    export OPENCODE_PROVIDER="z.ai"
    export OPENCODE_MODEL="GLM 4.7"
    export OPENAI_API_KEY=$(${pkgs.fnox}/bin/fnox get Z_AI_API_KEY)
    ${pkgs.opencode}/bin/opencode "$@"
  '');

  # Base packages that should always be available
  basePackages = with pkgs; [
    claude-code
    claude-monitor
    cursor-cli
    gemini-cli
  ];

  # Conditional packages that depend on fnox
  conditionalPackages = lib.optionals (pkgs ? fnox) [
    opencode-wrapper
  ];
in
{
  home.packages = basePackages ++ conditionalPackages;
}
