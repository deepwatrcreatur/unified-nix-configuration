{ config, pkgs, ... }:
{
  imports = [ ../../../../modules/nh.nix ];

  programs.nh = {
    flake = "/home/deepwatrcreatur/flakes/unified-nix-configuration";
  };
}
