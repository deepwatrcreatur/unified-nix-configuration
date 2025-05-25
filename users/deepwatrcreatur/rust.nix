# users/deepwatrcreatur/rust.nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    rustup
  ];

  home.sessionPath = [
    "$HOME/.cargo/bin"
  ];

  home.sessionVariables = {
    RUSTUP_HOME = "$HOME/.rustup";
    CARGO_HOME = "$HOME/.cargo";
  };
}

