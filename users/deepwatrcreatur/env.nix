{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.sessionVariables = {
    NH_FLAKE = "${config.home.homeDirectory}/flakes/unified-nix-configuration";
  };
}
