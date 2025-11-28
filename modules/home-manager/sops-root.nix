# modules/home-manager/sops-root.nix
{ config, pkgs, lib, inputs, ... }:

let
  globalSopsSecretsDir = toString (builtins.path { path = ../../secrets; });
in
{
  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  sops.secrets."github-token-root" = {
    sopsFile = "${globalSopsSecretsDir}/github-token.txt.enc";
    path = "${config.home.homeDirectory}/.config/git/github-token";
    mode = "0600";
  };
}
