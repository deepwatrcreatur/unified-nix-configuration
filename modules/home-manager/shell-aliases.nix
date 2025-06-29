# modules/home-manager/shell-aliases.nix

{ config, pkgs, lib, ... }:

{
  home.shellAliases = {
    ls = "lsd";
    ll = "lsd -l";
    la = "lsd -a";
    lla = "lsd -la";
    ".." = "cd ..";
    update = "just update";
    nh-update = "just nh-update";
  } // lib.optionalAttrs (pkgs.stdenv.isDarwin) {
    brew = "/opt/homebrew/bin/brew";
    xcode = "open -a Xcode";
  };
}
