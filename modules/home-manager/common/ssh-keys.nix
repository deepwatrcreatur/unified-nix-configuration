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
  
  # Use activation script to ensure .ssh directory permissions
  home.activation.fixSshPermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p $HOME/.ssh
    $DRY_RUN_CMD chmod 700 $HOME/.ssh
  '';
}