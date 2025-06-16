# modules/home-manager/gnupg-cli.nix
{ config, pkgs, lib, inputs, ... }:

{
  # This enables the gpg command-line tool
  programs.gpg = {
    enable = true;
  };

  # This configures the gpg-agent service
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    # Use the package directly, not a string reference
    pinentryPackage = pkgs.pinentry-ncurses;
    # defaultCacheTtl = 10800; # 3 hours
    # maxCacheTtl = 10800;   # 3 hours
  };
}
