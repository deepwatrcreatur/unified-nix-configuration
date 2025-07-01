# modules/home-manager/shell-aliases.nix

{ config, pkgs, lib, ... }:

{
  home.shellAliases = {
    ls = "lsd";
    ll = "lsd -l";
    la = "lsd -a";
    lla = "lsd -la";
    ".." = "cd ..";
    update = "just --justfile ~/.justfile update";
    nh-update = "just --justfile ~/.justfile nh-update";
  } // lib.optionalAttrs (pkgs.stdenv.isDarwin) {
    xcode = "open -a Xcode";
  };
}
