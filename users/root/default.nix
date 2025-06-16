{ config, pkgs, lib, ... }:
{
  imports = [
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/rename.nix
    ];
  
  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
  ];

  programs.home-manager.enable = true;
}
