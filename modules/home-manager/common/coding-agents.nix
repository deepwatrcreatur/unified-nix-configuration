{
  config,
  pkgs,
  lib,
  ...
}:

let
  opencode-wrapper = pkgs.writeShellScriptBin "opencode" ''
    #!/usr/bin/env bash
    export OPENCODE_PROVIDER="z.ai"
    export OPENCODE_MODEL="GLM 4.7"
    export OPENAI_API_KEY=$(${pkgs.fnox}/bin/fnox get Z_AI_API_KEY)
    ${pkgs.opencode}/bin/opencode "$@"
  '';
in
{
  home.packages = with pkgs; [
    claude-code
    claude-monitor
    cursor-cli
    gemini-cli
    opencode-wrapper
  ];
}
