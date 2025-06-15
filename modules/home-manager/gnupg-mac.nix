# modules/home-manager/gnupg-mac.nix
{ config, pkgs, lib, ... }:

{
  programs.gnupg = {
    enable = true;
    pinentry.enable = true;
    pinentry.program = "${pkgs.pinentry-mac}/bin/pinentry-mac";
  };
}
