# modules/home-manager/gpg-mac.nix
{ config, pkgs, lib, inputs, ... }:

{
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry_mac;
    # For macOS, you often need to enable SSH support in the agent
    # if you use GPG keys for SSH authentication.
    enableSshSupport = true;
  };

  #home.packages = [ pkgs.pinentry_mac ];
}
