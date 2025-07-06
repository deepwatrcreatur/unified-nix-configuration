{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    ./sops.nix
    ./rbw.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/rename.nix
    ../../modules/home-manager/zoxide.nix
    ../../modules/home-manager/gemini-cli.nix
    ../../modules/home-manager/claude-code.nix
    ../../modules/home-manager/npm.nix
    ../../modules/home-manager/env.nix
    ../../modules/home-manager/bitwarden-cli.nix
    ../../modules/home-manager/rclone.nix
  ];
  
  programs.bitwarden-cli = {
    enable = true;
  };

  home.username = "deepwatrcreatur";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    go
    chezmoi
    stow
    mix2nix
  ];
}
