{ config, lib, ... }:

let
  # Get all .pub files from the ssh-keys directory
  sshKeysDir = ../../../ssh-keys;
  pubKeyFiles = builtins.attrNames (
    lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".pub" name) (
      builtins.readDir sshKeysDir
    )
  );

  # Read content of each public key file and clean whitespace
  pubKeys = map (file: lib.strings.trim (builtins.readFile (sshKeysDir + "/${file}"))) pubKeyFiles;
in
{
  # Set SSH authorized keys for the main user
  users.users.deepwatrcreatur = {
    openssh.authorizedKeys.keys = pubKeys;
  };

  # Ensure SSH service is enabled
  services.openssh.enable = lib.mkDefault true;
}
