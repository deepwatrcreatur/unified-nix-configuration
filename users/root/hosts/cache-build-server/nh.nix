{ config, pkgs, ... }:
{
  imports = [ ../../../../modules/nh.nix ];

  programs.nh = {
    flake = "/root/flakes/unified-nix-configuration";
  };
}
