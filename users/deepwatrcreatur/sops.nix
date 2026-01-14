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
  sopsSecretsDirPath = builtins.path { path = ./secrets; };
  sopsSecretsDir = toString sopsSecretsDirPath;

  # Auto-wire simple one-value secrets.
  # Convention: any `*.txt.enc` file is SOPS-encrypted JSON with a top-level `data` key.
  # Secret names are derived from the filename:
  # - strip `.txt.enc`
  # - lowercase
  # - replace `.` with `-`
  secretsDirEntries = builtins.readDir sopsSecretsDirPath;
  secretFiles = builtins.attrNames secretsDirEntries;
  txtEncFiles = lib.filter (
    f: secretsDirEntries.${f} == "regular" && lib.hasSuffix ".txt.enc" f
  ) secretFiles;

  # Auto-wire YAML secrets where the filename encodes the key to extract.
  # Convention: `<name>__<key>.yaml.enc` -> secret name `<name>`, format `yaml`, key `<key>`.
  yamlEncFiles = lib.filter (
    f: secretsDirEntries.${f} == "regular" && lib.hasSuffix ".yaml.enc" f
  ) secretFiles;

  yamlKeyFile = file: builtins.match "^(.*)__([^/]+)\\.yaml\\.enc$" file;
  yamlKeyFiles = lib.filter (f: yamlKeyFile f != null) yamlEncFiles;

  autoYamlSecrets = lib.listToAttrs (
    map (
      file:
      let
        m = yamlKeyFile file;
        base = builtins.elemAt m 0;
        keyName = builtins.elemAt m 1;
        name = lib.toLower (lib.replaceStrings [ "." ] [ "-" ] base);
      in
      {
        inherit name;
        value = {
          sopsFile = "${sopsSecretsDir}/${file}";
          format = "yaml";
          key = keyName;
          mode = "0600";
        };
      }
    ) yamlKeyFiles
  );

  autoTxtSecrets = lib.listToAttrs (
    map (
      file:
      let
        base = lib.removeSuffix ".txt.enc" file;
        name = lib.toLower (lib.replaceStrings [ "." ] [ "-" ] base);
      in
      {
        inherit name;
        value = {
          sopsFile = "${sopsSecretsDir}/${file}";
          format = "json";
          key = "data";
          mode = "0600";
        };
      }
    ) txtEncFiles
  );

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

      secrets =
        autoTxtSecrets
        // autoYamlSecrets
        // {
          # Binary / structured secrets keep explicit config.

          "oauth_creds" = {
            sopsFile = "${sopsSecretsDir}/oauth_creds.json.enc";
            format = "binary";
            path = "${config.home.homeDirectory}/.gemini/oauth_creds.json";
            mode = "0600";
          };

          "bitwarden_data_json" = {
            sopsFile = "${sopsSecretsDir}/data.json.enc";
            format = "binary";
            path = "${config.xdg.configHome}/Bitwarden CLI/data.json";
            mode = "0600";
          };
        };
    };
  };
}
