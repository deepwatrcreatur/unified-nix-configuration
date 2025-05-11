{ config, pkgs, lib, ... }:
{
  imports = [
   ../modules/home-manager/fish-shared.nix
   ./git.nix
  ];

  home.username = "deepwatrcreatur";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    helix
    fzf
    bat
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
  ];

  home.file.".terminfo" = {
    source = ../../modules/home-manager/terminfo; 
    recursive = true;
  };

  programs.starship.enable = true;
  #programs.tmux.enable = true;
  programs.home-manager.enable = true;

  home.sessionPath = [
    "$HOME/.cargo/bin"
    "/run/current-system/sw/bin"
     ];
  home.sessionVariables = {
    RUSTUP_HOME = "$HOME/.rustup";
    CARGO_HOME = "$HOME/.cargo";

  #programs.mako.enable = lib.mkIf pkgs.stdenv.isLinux true;
  };
}
