# modules/home-manager/gnupg-mac.nix
{ config, pkgs, lib, inputs, ... }:

{
  imports = [ inputs.home-manager.modules.programs.gnupg ];

  programs.gnupg = {
    enable = true;
    pinentry.enable = true;
    pinentry.program = "${pkgs.pinentry_mac}/bin/pinentry-mac";
  };
}
