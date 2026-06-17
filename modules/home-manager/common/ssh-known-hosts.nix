# modules/home-manager/common/ssh-known-hosts.nix
# Manages known SSH host keys for common infrastructure
# Uses lib/hosts.nix as single source of truth
{ config, lib, pkgs, inputs, ... }:

let
  hostsData = import ../../../lib/hosts.nix;

  # Filter hosts that should be in SSH config
  sshHostEntries =
    builtins.concatLists (
      map
        (name:
          let host = hostsData.hosts.${name}; in
          if
            (host.includeSsh or true)
            && (
              (host.sshHostname or null) != null
              || (host.ip or null) != null
              || (host.hostname or null) != null
            )
          then
            [ { entryName = name; inherit host; } ]
            ++ map (alias: { entryName = alias; inherit host; }) (host.aliases or [ ])
          else
            [ ])
        (builtins.attrNames hostsData.hosts)
    );

  # Generate Host entry for each host
  hostEntry = entry:
    let
      hostname = entry.host.sshHostname or entry.host.hostname or entry.host.ip;
      user = entry.host.sshUser or "deepwatrcreatur";
    in ''
      Host ${entry.entryName}
          Hostname ${hostname}
          user ${user}
    '';

  # Generate ssh-config content for ssh-keys-manager to parse
  sshConfigContent = builtins.concatStringsSep "\n" (map hostEntry sshHostEntries);
  sshConfigFile = builtins.toFile "ssh-config-generated" sshConfigContent;

in {
  imports = [
    inputs.ssh-keys-manager.homeManagerModules.default
  ];

  programs.ssh-known-hosts-manager = {
    enable = true;
    keysDirectory = ../../../ssh-keys;
    sshConfigFile = sshConfigFile;
    outputFile = ".ssh/known_hosts_managed";
  };
}
