{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./sops.nix # <--- Import sops configuration
    ./git.nix # <--- Import git configuration
    ../../modules/home-manager/git.nix # Keep this import if it provides other common git modules
    ../../modules/home-manager/gpg-cli.nix
    ../../modules/home-manager
  ];

  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "25.11";

  # Allow root to manage Home Manager
  programs.home-manager.enable = true;
}
