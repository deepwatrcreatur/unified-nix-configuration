{ config, pkgs, ... }:
{
  imports = [ ../../../../modules/nh.nix ];

  programs.nh = {
    flake = "/Users/deepwatrcreatur/flakes/unified-nix-configuration";
  };
}
