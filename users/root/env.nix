{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.sessionVariables = {
    NH_FLAKE = "/root/flakes/unified-nix-configuration";
  };
}
