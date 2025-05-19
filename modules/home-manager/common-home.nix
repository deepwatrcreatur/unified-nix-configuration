# modules/home-manager/common-home.nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ./nushell
    ./helix.nix
    ./fish-shared.nix
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
    jj
    lazygit
    lazyjj
    nil
    nixd
    nixpkgs-fmt
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
