# modules/home-manager/gnupg-cli.nix
{ config, pkgs, lib, inputs, ... }:

{
  programs.gpg = {
    enable = true;
    agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-curses; # Correct pinentry for CLI Linux
      # defaultCacheTtl = 3600*3;
      # enableSshSupport = true;
    };
  };
}
