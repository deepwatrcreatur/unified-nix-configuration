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
  # Home Manager way to set SSH authorized keys
  home.file.".ssh/authorized_keys".text = lib.concatStringsSep "\n" pubKeys;
  
  # Ensure .ssh directory has correct permissions
  home.file.".ssh/authorized_keys".onChange = ''
    chmod 600 ~/.ssh/authorized_keys
    chmod 700 ~/.ssh
  '';
}