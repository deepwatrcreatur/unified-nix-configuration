# modules/home-manager/cargo-binstall.nix
{ pkgs, ... }:

{
  home.packages = [
    pkgs.rustc # Provides `cargo`
    pkgs.cargo-binstall
  ];

  home.sessionVariables = {
    PATH = "$HOME/.cargo/bin:$PATH";
  };
}
