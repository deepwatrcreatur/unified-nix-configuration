# modules/home-manager/common/ssh-known-hosts.nix
# Manages known SSH host keys for common infrastructure
{ config, lib, pkgs, ... }:

let
  sshKeysDir = ../../../ssh-keys;
  
  # Hostname to IP mapping from ssh-config
  hostToIP = {
    gateway = "10.10.10.1";
    workstation = "localhost";
    # Add more as needed
  };
  
  # Read host keys (pattern: {hostname}-host-ed25519.pub)
  hostKeyFiles = builtins.attrNames (
    lib.filterAttrs (name: type: 
      type == "regular" && lib.hasSuffix "-host-ed25519.pub" name
    ) (builtins.readDir sshKeysDir)
  );
  
  # Convert to known_hosts format with hostname,IP
  knownHostsEntries = lib.concatMapStringsSep "\n" (file:
    let
      hostname = lib.removeSuffix "-host-ed25519.pub" file;
      key = lib.strings.trim (builtins.readFile (sshKeysDir + "/${file}"));
      # Add IP if we have a mapping, otherwise just hostname
      hostPattern = if hostToIP ? ${hostname}
                    then "${hostname},${hostToIP.${hostname}}"
                    else hostname;
    in
    "${hostPattern} ${key}"
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
