{ config, lib, ... }:

let
  # Get all .pub files from the ssh-keys directory
  sshKeysDir = ../../../ssh-keys;
  pubKeyFiles = builtins.attrNames (lib.filterAttrs 
    (name: type: type == "regular" && lib.hasSuffix ".pub" name)
    (builtins.readDir sshKeysDir));
  
  # Read content of each public key file
  pubKeys = map (file: builtins.readFile (sshKeysDir + "/${file}")) pubKeyFiles;
in
{
  # Home Manager way to set SSH authorized keys with proper permissions
  home.file.".ssh/authorized_keys" = {
    text = lib.concatStringsSep "\n" pubKeys;
    mode = "0600";  # Set correct permissions directly
  };
  
  # Ensure .ssh directory exists with correct permissions
  home.file.".ssh/.keep" = {
    text = "";
    mode = "0700";
  };
}