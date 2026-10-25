{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ./sops.nix # <--- Temporarily disabled sops configuration
    ./git.nix # <--- Import git configuration
    ./env.nix
    ../../modules/home-manager/git.nix # Keep this import if it provides other common git modules
    ../../modules/home-manager/git-ssh-signing.nix
    ../../modules/home-manager
    ../../modules/home-manager/fastfetch.nix
  ];

  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "25.11";

  # Allow root to manage Home Manager
  programs.home-manager.enable = true;

  programs.zellij-vivid-rounded = {
    enable = true;
  };

  programs.fastfetch-custom = {
    enable = true;
  };
}
