
# home/deepwatrcreatur.nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ../modules/home-manager/fish-shared.nix
    ../../modules/home-manager/common-home.nix
    ./git.nix
   ];
  
  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    lsd
    fish
    # ...other packages you want...
  ];
    
  # Copy .terminfo files into place
  home.file.".terminfo" = {
    source = ../../modules/home-manager/terminfo; # Place your terminfo files in home/terminfo/
    recursive = true;
  };

  programs.home-manager.enable = true;
}
