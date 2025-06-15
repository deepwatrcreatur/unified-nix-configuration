{ config, pkgs, lib, ... }:
{
  imports = [
    ../../modules/home-manager/git.nix
    ];
  
  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    gnupg
  ];

  programs.home-manager.enable = true;
}
