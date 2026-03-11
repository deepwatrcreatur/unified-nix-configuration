# modules/home-manager/common/ssh-known-hosts.nix
# Manages known SSH host keys for common infrastructure
{ config, lib, pkgs, ... }:

let
  sshKeysDir = ../../../ssh-keys;
  sshConfigFile = ../ssh-config;
  
  # Parse ssh-config to extract hostname -> IP mappings
  sshConfigContent = builtins.readFile sshConfigFile;
  
  # Extract Host and Hostname pairs from ssh-config
  # This is a simple parser - matches "Host X" followed by "Hostname Y"
  parseSSHConfig = content:
    let
      lines = lib.splitString "\n" content;
      # Remove comments and trim
      cleanLines = map (line: lib.strings.trim line) (lib.filter (line: 
        !(lib.hasPrefix "#" (lib.strings.trim line)) && (lib.strings.trim line) != ""
      ) lines);
      
      # Parse pairs of Host/Hostname
      parseLines = lines: acc:
        if lines == [] then acc
        else
          let
            line = lib.head lines;
            rest = lib.tail lines;
          in
          if lib.hasPrefix "Host " line && line != "Host *" then
            let
              hostname = lib.removePrefix "Host " line;
              # Look ahead for Hostname line
              nextLine = if rest != [] then lib.head rest else "";
              hasIP = lib.hasPrefix "Hostname " nextLine || lib.hasPrefix "HostName " nextLine;
              ip = if hasIP then 
                     lib.removePrefix "Hostname " (lib.removePrefix "HostName " nextLine)
                   else null;
            in
            if ip != null then
              parseLines (lib.tail rest) (acc // { ${hostname} = ip; })
            else
              parseLines rest acc
          else
            parseLines rest acc;
    in
    parseLines cleanLines {};
  
  hostToIP = parseSSHConfig sshConfigContent;
  
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
      # IPs auto-extracted from ssh-config
      ${knownHostsEntries}
    '';
  };
}
