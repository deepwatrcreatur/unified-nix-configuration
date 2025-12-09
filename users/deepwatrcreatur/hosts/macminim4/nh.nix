{ config, pkgs, ... }:
{
  imports = [ ../../../../modules/nh.nix ];

  programs.nh = {
    flake = "/Users/deepwatrcreatur/unified-nix-configuration";
  };
}
