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
    isNormalUser = true;
    openssh.authorizedKeys.keys = pubKeys;
  };

  # Ensure SSH service is enabled
  services.openssh.enable = lib.mkDefault true;
  
  # Enable hybrid authorized_keys: NixOS-managed + user-managed dynamic keys
  services.openssh.extraConfig = ''
    # Check both NixOS-managed and user-managed keys
    AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys_dynamic
  '';
  
  # Create mutable authorized_keys_dynamic file
  systemd.tmpfiles.rules = [
    "d /home/deepwatrcreatur/.ssh 0700 deepwatrcreatur users - -"
    "f /home/deepwatrcreatur/.ssh/authorized_keys_dynamic 0600 deepwatrcreatur users - -"
  ];
}
