# modules/home-manager/sops-deepwatrcreatur.nix
# This module configures sops for deepwatrcreatur within Home Manager.
{ config, lib, pkgs, inputs, ... }:

let
  # Path to your shared secrets directory relative to the flake root.
  sopsSecretsDir = toString (builtins.path { path = ./../../secrets; });
in
# The `lib.mkIf` should wrap the entire module, not just the `config` attribute.
# This makes the module itself conditional on `config.my.sops.enable`.
lib.mkIf config.my.sops.enable {

  # This 'imports' must be at the top-level of the module, alongside 'options' and 'config'.
  # It correctly tells Nix that *this module* uses options from `sops-nix`'s HM module.
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  # Options defined here are part of THIS module's interface.
  # (Your original module had this nested inside a conditional config block, which is also incorrect.)
  options.my.sops = {
    enable = lib.mkEnableOption "Sops integration for home-manager"; # This option should be defined here
  };


  # All actual configuration goes into the 'config' attribute.
  config = {
    home.packages = [ pkgs.sops ];

    home.file."${config.xdg.configHome}/sops/.sops.yaml" = {
      source = "${sopsSecretsDir}/.sops.yaml";
      mode = "0400";
    };

    # Define specific sops secrets for deepwatrcreatur here
    # Example: GPG key for Git commits
    # sops.secrets."git-signing-key" = {
    #   sopsFile = "${sopsSecretsDir}/user-secrets/deepwatrcreatur-git-keys.yaml.enc";
    #   key = "gpg_signing_key";
    #   path = "${config.xdg.configHome}/git/gpg-signing-key.asc";
    #   mode = "0600";
    # };
  };
}
