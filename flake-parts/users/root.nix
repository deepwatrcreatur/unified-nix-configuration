
# home/deepwatrcreatur.nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ../../modules/home-manager/common-home.nix
    ../../users/deepwatrcreatur/git.nix
   ];
  
  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
  ];
    
}
