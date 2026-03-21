# modules/home-manager/common/ssh-config.nix
# Generates SSH config from lib/hosts.nix - single source of truth
{ config, lib, pkgs, ... }:

let
  hostsData = import ../../../lib/hosts.nix;

  # Filter hosts that should be in SSH config
  sshHosts = lib.filterAttrs (name: host:
    (host.includeSsh or true) && (host.ip != null || host.hostname or null != null)
  ) hostsData.hosts;

  # Generate matchBlocks from hosts
  matchBlocks = lib.mapAttrs (name: host: {
    hostname = host.hostname or host.ip;
    user = host.sshUser or "deepwatrcreatur";
  }) sshHosts // {
    # Wildcard match block for default settings
    "*" = {
      userKnownHostsFile = "~/.ssh/known_hosts_dynamic ~/.ssh/known_hosts_managed";
    };
  };

in {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Global SSH settings
    extraConfig = ''
      # Global settings for all hosts
      SendEnv LANG LC_*
      MACs hmac-md5,hmac-sha1
      ForwardX11 no
      ForwardAgent yes
      AddressFamily inet
      ServerAliveInterval 15
      ConnectTimeout 20
    '';

    # Generated host configurations
    inherit matchBlocks;
  };
}
