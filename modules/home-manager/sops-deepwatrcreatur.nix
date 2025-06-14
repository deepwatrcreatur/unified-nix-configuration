# modules/home-manager/sops-deepwatrcreatur.nix
# This module unconditionally configures sops for deepwatrcreatur within Home Manager.
{ config, lib, pkgs, inputs, ... }: # Module arguments

let
  sopsSecretsDir = toString (builtins.path { path = ./../../secrets; });
in
{ # This is the single top-level attribute set for the module

  # Imports must be declared here.
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  # Config must be declared here.
  config = {
    home.packages = [ pkgs.sops ];

    home.file."${config.xdg.configHome}/sops/.sops.yaml".source = "${sopsSecretsDir}/.sops.yaml";
    home.file."${config.xdg.configHome}/sops/.sops.yaml".mode = "0400";
    };

    # Uncomment and configure your sops.secrets entries as needed
    # sops.secrets."git-signing-key" = {
    #   sopsFile = "${sopsSecretsDir}/user-secrets/deepwatrcreatur-git-keys.yaml.enc";
    #   key = "gpg_signing_key";
    #   path = "${config.xdg.configHome}/git/gpg-signing-key.asc";
    #   mode = "0600";
    # };
}
