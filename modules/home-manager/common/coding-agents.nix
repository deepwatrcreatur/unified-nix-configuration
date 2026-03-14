{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  codingAgents = import ../coding-agents-registry.nix {
    inherit pkgs inputs;
  };
in
{
  home.packages = [
    pkgs.claude-monitor
    inputs.claude-statusline-flake.packages.${pkgs.stdenv.hostPlatform.system}.default
  ] ++ map (agent: agent.package) codingAgents;
}
