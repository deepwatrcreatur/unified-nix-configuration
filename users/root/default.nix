{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./sops.nix # Import SOPS configuration for attic token and other secrets
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
