# modules/home-manager/gnupg-mac.nix
{ config, pkgs, lib, inputs, ... }:

{
  #imports = [ inputs.home-manager.modules.programs.gpg ];

  programs.gpg = {
    enable = true;
    agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry_mac; # Correct pinentry for macOS
    };
    # settings = {
    #   utf8-strings = true;
    #   fixed-list-mode = true;
    #   keyid-format = "0xlong";
    # };
  };
}
