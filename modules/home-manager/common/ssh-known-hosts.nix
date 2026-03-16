# modules/home-manager/common/ssh-known-hosts.nix
# Manages known SSH host keys for common infrastructure
# Uses lib/hosts.nix as single source of truth
{ config, lib, pkgs, inputs, ... }:

let
  hostsData = import ../../../lib/hosts.nix;

  # Filter hosts that should be in SSH config
  sshHosts = builtins.filter (name:
    let host = hostsData.hosts.${name}; in
    (host.includeSsh or true) && ((host.ip or null) != null || (host.hostname or null) != null)
  ) (builtins.attrNames hostsData.hosts);

  # Generate Host entry for each host
  hostEntry = name:
    let
      host = hostsData.hosts.${name};
      hostname = host.hostname or host.ip;
      user = host.sshUser or "deepwatrcreatur";
    in ''
      Host ${name}
          Hostname ${hostname}
          user ${user}
    '';

  # Generate ssh-config content for ssh-keys-manager to parse
  sshConfigContent = builtins.concatStringsSep "\n" (map hostEntry sshHosts);
  sshConfigFile = pkgs.writeText "ssh-config-generated" sshConfigContent;

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
