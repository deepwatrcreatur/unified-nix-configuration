# modules/home-manager/gnupg-desktop-linux.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [ inputs.home-manager.modules.programs.gnupg ];
  
  programs.gnupg = {
    enable = true;
    agent = {
      enable = true;
      enableSshSupport = true;
      pinentry.program = "${pkgs.pinentry-gnome3}/bin/pinentry";
    };
  };
}
