{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/gpg-cli.nix
    ../../modules/home-manager
  ];
  
  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "25.05";
  home.packages = with pkgs; [ sops ];
  programs.home-manager.enable = true;
  
}
