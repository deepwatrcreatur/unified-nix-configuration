# users/deepwatrcreatur/sops.nix
# This module unconditionally configures sops for deepwatrcreatur within Home Manager.
{ config, pkgs, lib, inputs, ... }: # Module arguments

let
  sopsSecretsDir = toString (builtins.path { path = ./secrets; });

  # Determine the target path for data.json based on the system
  #bitwardenDataJsonPath = if pkgs.stdenv.isDarwin  
  #  then "${config.home.homeDirectory}/Library/Application Support/Bitwarden CLI/data.json"
  #  else "${config.xdg.configHome}/Bitwarden CLI/data.json";
in
{ # This is the single top-level attribute set for the module

  # Imports must be declared here.
  # Note: sops-nix home-manager module is imported at the system level

  # Config must be declared here.
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

      secrets."gpg-private-key" = {
        sopsFile = "${sopsSecretsDir}/gpg-private-key.asc.enc";
        format = "binary";
        path = "${config.home.homeDirectory}/.gnupg/private-key.asc";
        mode = "0600";
      };

      secrets."BW_SESSION" = {
        sopsFile = "${sopsSecretsDir}/bitwarden.yaml";
        format = "yaml";
        path = "${config.xdg.configHome}/sops/BW_SESSION";
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
        format = "binary";
        path = "${config.home.homeDirectory}/.config/git/github-token";
        mode = "0600";
      };

      secrets."attic-client-token" = {
        sopsFile = "${sopsSecretsDir}/attic-client-token.yaml.enc";
        format = "yaml";
        path = "${config.home.homeDirectory}/.config/sops/attic-client-token";
        mode = "0600";
      };
    };
  };
}
