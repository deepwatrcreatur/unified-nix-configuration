{ config, pkgs, lib, ... }:
{
  imports = [ ../../modules/home-manager/fish-shared.nix ];
  
  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
  ];
    
  #home.file.".terminfo" = {
  #  source = ../../modules/home-manager/terminfo;
  #  recursive = true;
  #};

  programs.home-manager.enable = true;
}
