{ config, lib, ... }:

let
  # Get all .pub files from the ssh-keys directory  
  sshKeysDir = ../../../ssh-keys;
  
  # Debug: ensure directory exists and list contents
  pubKeyFiles = builtins.attrNames (lib.filterAttrs 
    (name: type: type == "regular" && lib.hasSuffix ".pub" name)
    (builtins.readDir sshKeysDir));
  
  # Read content of each public key file
  pubKeys = map (file: builtins.readFile (sshKeysDir + "/${file}")) pubKeyFiles;
  
  # Debug output
  debugInfo = "# SSH Keys loaded from ${toString sshKeysDir}\n# Found files: ${toString pubKeyFiles}\n";
in
{
  # Home Manager way to set SSH authorized keys  
  home.file.".ssh/authorized_keys".text = debugInfo + lib.concatStringsSep "\n" pubKeys;
  
  # Use activation script to fix SSH permissions after files are created
  home.activation.fixSshPermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ ! -v DRY_RUN ]]; then
      mkdir -p $HOME/.ssh
      chmod 700 $HOME/.ssh
      if [[ -f $HOME/.ssh/authorized_keys ]]; then
        chmod 600 $HOME/.ssh/authorized_keys
        echo "Fixed SSH permissions: .ssh (700), authorized_keys (600)"
      fi
    fi
  '';
}