{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/gpg-cli.nix
    ../../modules/home-manager
  ];
  
  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    cursor-cli
  ];
  # Allow root to manage Home Manager
  programs.home-manager.enable = true;
  
}
