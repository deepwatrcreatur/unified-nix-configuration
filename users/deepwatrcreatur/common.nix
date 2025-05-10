{ config, pkgs, lib, ... }:
{
  imports = [
   ../modules/home-manager/fish-shared.nix
   ./git.nix
  ];

  home.username = "deepwatrcreatur";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    fzf
    grc
    bat
    tmux
    starship
    fastfetch
    neovim
    python3
    go
    gh
    rustup
    nil
    nixd
    nixpkgs-fmt
    chezmoi
    stow
    glow
    mix2nix
    lsd
    fish
  ];

  # Copy .terminfo files into place
  home.file.".terminfo" = {
    source = ../../modules/home-manager/terminfo; # Place your terminfo files in home/terminfo/
    recursive = true;
  };

  programs.starship.enable = true;
  programs.tmux.enable = true;
  programs.home-manager.enable = true;

  home.sessionPath = [
    "$HOME/.cargo/bin"
    "/run/current-system/sw/bin"
     ];
  home.sessionVariables = {
    RUSTUP_HOME = "$HOME/.rustup";
    CARGO_HOME = "$HOME/.cargo";
  };
}
