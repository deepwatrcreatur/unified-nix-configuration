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
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  # Config must be declared here.
  config = {
    home.packages = [ pkgs.sops ];

    home.file."${config.xdg.configHome}/sops/.sops.yaml" = {
      source = "${sopsSecretsDir}/sops.yaml";
      force = true; # Ensure it’s a regular file, not a symlink
    };

    # Configure SOPS with age key
    sops = {
      age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

      secrets."oauth_creds" = {
        sopsFile = "${sopsSecretsDir}/oauth_creds.json.enc";
        format = "binary";
        path = "${config.home.homeDirectory}/.gemini/oauth_creds.json";
        mode = "0600";
      };

      secrets."BW_SESSION" = {
        sopsFile = "${sopsSecretsDir}/bitwarden.yaml";
        format = "yaml";
      };

      secrets."bitwarden_data_json" = {
        sopsFile = "${sopsSecretsDir}/data.json.enc";
        format = "binary";
        #path = bitwardenDataJsonPath;
        path = "${config.home.homeDirectory}/.config/Bitwarden CLI/data.json";
        mode = "0600";
      };
    };
  };
}
