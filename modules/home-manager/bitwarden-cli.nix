# modules/home-manager/bitwarden-cli.nix

{ config, pkgs, lib, inputs, ... }:

{
  home.packages = lib.optionals pkgs.stdenv.isLinux (with pkgs; [
    bitwarden-cli
  ]);
}
