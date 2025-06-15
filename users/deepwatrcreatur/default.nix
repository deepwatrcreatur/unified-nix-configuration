{ config, pkgs, ... }:
{
  imports = [
    ../../modules/home-manager/git.nix
  ];

  home.username = "deepwatrcreatur";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    go
    chezmoi
    stow
    mix2nix
  ];
}
