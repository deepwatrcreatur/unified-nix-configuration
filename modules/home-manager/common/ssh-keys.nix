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
  
  # Use activation script to fix SSH permissions after files are created
  home.activation.fixSshPermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p $HOME/.ssh
    $DRY_RUN_CMD chmod 700 $HOME/.ssh
    $DRY_RUN_CMD chmod 600 $HOME/.ssh/authorized_keys
  '';
}