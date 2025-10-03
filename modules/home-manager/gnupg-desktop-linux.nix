# modules/home-manager/gnupg-desktop-linux.nix
{ config, pkgs, lib, inputs, ... }:

{
  programs.gnupg = {
    enable = true;
    agent = {
      enable = true;
      enableSshSupport = true;
      pinentry.program = "${pkgs.pinentry-gnome3}/bin/pinentry";
    };
  };
}