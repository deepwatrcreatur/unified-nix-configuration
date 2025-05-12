# modules/home-manager/common-home.nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ./helix.nix
    ./fish-shared.nix
  ];

  home.packages = with pkgs; [
    lsd
    bat
    fzf
    fastfetch
    neovim    
  ];

  # Copy .terminfo files into place
  home.file.".terminfo" = {
    source = ../../modules/home-manager/terminfo;
    recursive = true;
  };

  programs.starship.enable = true;
  programs.home-manager.enable = true;
}
