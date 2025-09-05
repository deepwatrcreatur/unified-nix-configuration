{ config, pkgs, ... }:
{
  imports = [../../../../../modules/nh.nix];
  
  programs.nh = {
    flake = "/home/deepwatrcreatur/unified-nix-configuration";
  };
}
