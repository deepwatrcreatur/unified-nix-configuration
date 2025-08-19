{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/gpg-cli.nix
  ];
  
  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [ sops ];
  programs.home-manager.enable = true;
  
}
