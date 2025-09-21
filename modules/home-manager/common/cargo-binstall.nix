# modules/home-manager/cargo-binstall.nix
{ pkgs, config, lib, ... }:

{
  home.packages = lib.mkAfter [
    pkgs.cargo
    pkgs.cargo-binstall
  ];

  
}
