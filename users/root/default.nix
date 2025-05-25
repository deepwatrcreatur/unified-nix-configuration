{ config, pkgs, lib, ... }:
{
  imports = [
    ../../modules/home-manager/fish-shared.nix
    ../../modules/home-manager/starship.nix
    ];
  
  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
  ];
    

  programs.home-manager.enable = true;
}
