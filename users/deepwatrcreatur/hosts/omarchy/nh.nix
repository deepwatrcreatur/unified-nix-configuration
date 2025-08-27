{ config, pkgs, ... }:
{
  imports = [../../../../modules/nh.nix];
  
  programs.nh = {
    flake = "/Volumes/Work/unified-nix-configuration";
  };
}
