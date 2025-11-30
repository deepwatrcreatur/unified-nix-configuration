# modules/home-manager/sops-root.nix
{ config, pkgs, lib, inputs, ... }:

{
  sops.secrets."github-token-root" = {
    sopsFile = ../../users/root/secrets/github-token.txt.enc;
    path = "${config.home.homeDirectory}/.config/git/github-token";
    mode = "0600";
  };
}
