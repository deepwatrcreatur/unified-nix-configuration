# modules/home-manager/sops-deepwatrcreatur.nix
# This module configures sops for deepwatrcreatur within Home Manager.
{ config, lib, pkgs, inputs, ... }:

# Declare options at the top-level of the module.
# This makes the 'my.sops.enable' option available for 'config' merging.
options = {
  my.sops.enable = lib.mkEnableOption "Sops integration for home-manager user";
};

let
  sopsSecretsDir = toString (builtins.path { path = ./../../secrets; });
in
# The `lib.mkIf` now wraps the `config` attribute ONLY.
# The 'options' are declared unconditionally.
lib.mkIf config.my.sops.enable {

  # This 'imports' must be at the top-level of the module, alongside 'options' and 'config'.
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  # All actual configuration goes into the 'config' attribute.
  config = {
    home.packages = [ pkgs.sops ];

    home.file."${config.xdg.configHome}/sops/.sops.yaml" = {
      source = "${sopsSecretsDir}/.sops.yaml";
      mode = "0400";
    };

    # Uncomment and configure your sops.secrets entries as needed
    # sops.secrets."git-signing-key" = {
    #   sopsFile = "${sopsSecretsDir}/user-secrets/deepwatrcreatur-git-keys.yaml.enc";
    #   key = "gpg_signing_key";
    #   path = "${config.xdg.configHome}/git/gpg-signing-key.asc";
    #   mode = "0600";
    # };
  };
}
