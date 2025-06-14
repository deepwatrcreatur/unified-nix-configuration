# modules/home-manager/sops-deepwatrcreatur.nix
# This module configures sops for deepwatrcreatur within Home Manager.
{ config, lib, pkgs, inputs, ... }: # Module arguments

# The `let` binding for local variables must wrap the entire expression
# that uses those variables. In this case, it's the module's attribute set.
let
  sopsSecretsDir = toString (builtins.path { path = ./../../secrets; });
in

# The `lib.mkIf` wraps the *entire module definition* (the attribute set).
lib.mkIf config.my.sops.enable { # <--- This is the single top-level expression

  # Options declaration
  options = {
    my.sops.enable = lib.mkEnableOption "Sops integration for home-manager user";
  };

  # Imports
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  # The 'config' attribute
  config = {
    home.packages = [ pkgs.sops ];

    home.file."${config.xdg.configHome}/sops/.sops.yaml" = {
      source = "${sopsSecretsDir}/.sops.yaml"; # This variable is now in scope
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
