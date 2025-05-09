# home/deepwatrcreatur.nix
{ config, pkgs, lib, ... }:
{
  imports = [
   ../modules/home-manager/fish-shared.nix
   ../modules/home-manager/git.nix
  ];

  home.username = "deepwatrcreatur";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    lsd
    fish
    # ...other packages you want...
  ];

  # Copy .terminfo files into place
  home.file.".terminfo" = {
    source = ./terminfo; # Place your terminfo files in home/terminfo/
    recursive = true;
  };

  programs.home-manager.enable = true;
}
