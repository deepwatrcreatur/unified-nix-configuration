# modules/home-manager/cargo-binstall.nix
{ pkgs, config, ... }:

{
  home.packages = config.home.packages ++ [
    pkgs.cargo
    pkgs.cargo-binstall
  ];

  home.sessionVariables = {
    PATH = "$HOME/.cargo/bin:$PATH";
  };
}
