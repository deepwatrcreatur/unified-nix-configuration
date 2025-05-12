{ config, pkgs, lib, ... }:
{
  imports = [
  ../../modules/home-manager/common-home.nix
   ./git.nix
  ];

  home.username = "deepwatrcreatur";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
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
  ];

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
