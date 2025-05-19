# modules/home-manager/common-home.nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ./nushell
    ./helix
    ./fish-shared.nix
    ./jujutsu
  ];

  home.packages = with pkgs; [
    fish
    nushell
    lsd
    bat
    fzf
    fastfetch
    neovim
    gh
    git
    lazygit
    lazyjj
    python3
    glow
  ];

  # Copy .terminfo files into place
  home.file.".terminfo" = {
    source = ../../modules/home-manager/terminfo;
    recursive = true;
  };

  programs.home-manager.enable = true;
}
