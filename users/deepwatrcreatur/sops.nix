# users/deepwatrcreatur/sops.nix
# This module unconditionally configures sops for deepwatrcreatur within Home Manager.
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: # Module arguments

let
  sopsSecretsDir = toString (builtins.path { path = ./secrets; });

in
{
  # This is the single top-level attribute set for the module

  config = {
    home.packages = [ pkgs.sops ];

    home.file."${config.xdg.configHome}/sops/.sops.yaml" = {
      source = "${sopsSecretsDir}/sops.yaml";
      force = true; # Ensure it’s a regular file, not a symlink
    };

    # Configure SOPS with age key
    # Create the Bitwarden CLI directory
    home.file."${config.xdg.configHome}/Bitwarden CLI/.keep".text = "";

    sops = {
      age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

      secrets."oauth_creds" = {
        sopsFile = "${sopsSecretsDir}/oauth_creds.json.enc";
        format = "binary";
        path = "${config.home.homeDirectory}/.gemini/oauth_creds.json";
        mode = "0600";
      };

      secrets."bitwarden_data_json" = {
        sopsFile = "${sopsSecretsDir}/data.json.enc";
        format = "binary";
        path = "${config.xdg.configHome}/Bitwarden CLI/data.json";
        mode = "0600";
      };

      secrets."github-token" = {
        sopsFile = "${sopsSecretsDir}/github-token.txt.enc";
        format = "json";
        key = "data";
        mode = "0600";
      };
    };
  };
}
