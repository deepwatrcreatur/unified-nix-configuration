# users/deepwatrcreatur/sops.nix
# This module unconditionally configures sops for deepwatrcreatur within Home Manager.
{ config, lib, pkgs, inputs, ... }: # Module arguments

let
  sopsSecretsDir = toString (builtins.path { path = ./secrets; });
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
    };

    home.sessionVariables = {
      BW_SESSION = "$(cat ${config.sops.secrets.BW_SESSION.path})";
    };
    
    programs.nushell = {
      enable = true;
      environmentVariables = {
        BW_SESSION = ''$(cat ${config.sops.secrets.BW_SESSION.path} | tr -d '\n')'';
      };
    };
  };
}
