{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../../../../modules/home-manager/default.nix
  ];

  home.homeDirectory = "/home/deepwatrcreatur";

  home.stateVersion = "25.11";
}
