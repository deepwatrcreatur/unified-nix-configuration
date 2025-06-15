# modules/home-manager/gnupg-mac.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [ config.lib.home.programs.gnupg ];

  programs.gnupg = {
   enable = true;
   pinentry.enable = true;
   pinentry.program = "${pkgs.pinentry_mac}/bin/pinentry-mac";
  };
}
