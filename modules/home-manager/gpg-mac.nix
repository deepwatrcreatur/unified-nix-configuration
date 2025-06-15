# modules/home-manager/gnupg-mac.nix
{ config, pkgs, lib, inputs, ... }:

{
  #imports = [ inputs.home-manager.modules.programs.gpg ];

  programs.gpg = {
    enable = true;
    # settings = {
    #   utf8-strings = true;
    #   fixed-list-mode = true;
    #   keyid-format = "0xlong";
    # };
  };
  home.packages = with pkgs; [ gnupg pinentry_mac ];

  home.file.".gnupg/gpg-agent.conf".text = ''
    pinentry-program ${pkgs.pinentry_mac}/bin/pinentry-mac
  '';
}
