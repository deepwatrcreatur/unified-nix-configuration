# modules/home-manager/gnupg-mac.nix
{ config, pkgs, lib, inputs, ... }:

{
  programs.gnupg = {
    enable = true;
    pinentry.enable = true;
    pinentry.program = "${pkgs.pinentry_mac}/bin/pinentry-mac";
  };
}
