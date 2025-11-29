{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../modules/home-manager/sops-root.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/gpg-cli.nix
    ../../modules/home-manager
  ];
  
  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
  ];
  # Allow root to manage Home Manager
  programs.home-manager.enable = true;
  
}
