{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.sessionVariables = {
    NH_FLAKE = "${config.home.homeDirectory}/unified-nix-configuration";
  };
}
