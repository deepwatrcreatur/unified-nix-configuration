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
    # Create the Bitwarden CLI directory
    home.file."${config.xdg.configHome}/Bitwarden CLI/.keep".text = "";

    home.file.".gnupg/public-key.asc" = {
      source = "${sopsSecretsDir}/gpg-public-key.asc";
    };
    
    sops = {
      age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

      secrets."gpg-private-key" = {
        sopsFile = "${sopsSecretsDir}/gpg-private-key.asc.enc";
        format = "binary";
        path = "${config.home.homeDirectory}/.gnupg/private-key.asc";
        mode = "0600";
      };

      secrets."oauth_creds" = {
        sopsFile = "${sopsSecretsDir}/oauth_creds.json.enc";
        format = "binary";
        path = "${config.home.homeDirectory}/.gemini/oauth_creds.json";
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

      # Import GPG keys during activation
      home.activation.importGpgKeys = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $HOME/.gnupg
      $DRY_RUN_CMD chmod 700 $HOME/.gnupg
      $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --import $HOME/.gnupg/public-key.asc
      $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --import $HOME/.gnupg/private-key.asc
      $DRY_RUN_CMD echo "A116F3E1C37D5592D940BF05EF1502C27653693B:6:" | ${pkgs.gnupg}/bin/gpg --import-ownertrust
    '';
    };
  };
}
