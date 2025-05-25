
{ config, pkgs, ... }:
{
  imports = [
    
  ];

  home.username = "deepwatrcreatur";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    go
    chezmoi
    stow
    mix2nix
  ];

  home.sessionPath = [
    "/run/current-system/sw/bin"
  ];
}
