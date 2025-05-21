
{ config, pkgs, ... }:
{
  home.username = "deepwatrcreatur";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    go
    rustup
    chezmoi
    stow
    mix2nix
  ];

  home.sessionPath = [
    "$HOME/.cargo/bin"
    "/run/current-system/sw/bin"
  ];
  home.sessionVariables = {
    RUSTUP_HOME = "$HOME/.rustup";
    CARGO_HOME = "$HOME/.cargo";
  };
}
