{ config, pkgs, ... }:
{
  imports = [ ../../../../modules/nh.nix ];

  programs.nh = {
    flake = "/home/deepwatrcreatur/flakes-worktrees/unified-nix-configuration/main";
  };
}
