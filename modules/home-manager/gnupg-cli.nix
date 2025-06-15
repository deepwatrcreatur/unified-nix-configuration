# modules/home-manager/gnupg-cli.nix
{ config, pkgs, lib, inputs ... }:

{
  imports = [ inputs.home-manager.modules.programs.gnupg ];
  
  programs.gnupg = {
    enable = true;
    pinentry.enable = true;
    # Use a text-based pinentry program for non-graphical environments
    pinentry.program = "${pkgs.pinentry-curses}/bin/pinentry-curses";
  };
}
