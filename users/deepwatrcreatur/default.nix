
# home/deepwatrcreatur.nix
{ config, pkgs, lib, ... }:
{
  imports = [ ../modules/home/fish-shared.nix ];

  home.username = "deepwatrcreatur";
  home.homeDirectory = "/home/deepwatrcreatur";
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
