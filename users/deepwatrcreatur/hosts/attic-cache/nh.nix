{ config, pkgs, ... }:

{
  imports = [ ../../../../modules/nh.nix ];

  programs.nh = {
    flake = "/home/deepwatrcreatur/flakes/unified-nix-configuration";
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };
}
