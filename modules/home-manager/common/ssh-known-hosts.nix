# modules/home-manager/common/ssh-known-hosts.nix
# Manages known SSH host keys for common infrastructure
{ config, lib, pkgs, ... }:

let
  sshKeysDir = ../../../ssh-keys;
  
  # Read host keys (pattern: {hostname}-host-ed25519.pub)
  hostKeyFiles = builtins.attrNames (
    lib.filterAttrs (name: type: 
      type == "regular" && lib.hasSuffix "-host-ed25519.pub" name
    ) (builtins.readDir sshKeysDir)
  );
  
  # Convert to known_hosts format
  knownHostsEntries = lib.concatMapStringsSep "\n" (file:
    let
      hostname = lib.removeSuffix "-host-ed25519.pub" file;
      key = lib.strings.trim (builtins.readFile (sshKeysDir + "/${file}"));
    in
    "${hostname} ${key}"
  ) hostKeyFiles;
in
{
  # Create managed known_hosts file
  home.file.".ssh/known_hosts_managed" = {
    text = ''
      # NixOS-managed known_hosts (read-only)
      # Auto-generated from ssh-keys/*-host-ed25519.pub
      ${knownHostsEntries}
    '';
  };
}
