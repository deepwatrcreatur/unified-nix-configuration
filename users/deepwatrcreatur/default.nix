{ config, pkgs, ... }:
{
  imports = [
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/rename.nix
    ./sops.nix
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
