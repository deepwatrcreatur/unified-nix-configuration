# modules/home-manager/common/ssh-config.nix
# Generates SSH config from lib/hosts.nix - single source of truth
{ config, lib, pkgs, ... }:

let
  hostsData = import ../../../lib/hosts.nix;

  # Filter hosts that should be in SSH config
  sshHosts = lib.filterAttrs (name: host:
    (host.includeSsh or true) && (host.ip != null || host.hostname or null != null)
  ) hostsData.hosts;

  expandedSshHosts =
    lib.foldl'
      (acc: name:
        let
          host = sshHosts.${name};
          entries =
            [ { entryName = name; } ]
            ++ map (alias: { entryName = alias; }) (host.aliases or [ ]);
        in
        acc
        // builtins.listToAttrs (
          map
            (entry: {
              name = entry.entryName;
              value = host // { canonicalName = name; };
            })
            entries
        ))
      { }
      (builtins.attrNames sshHosts);

  hostSummary = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: host:
      let
        target = host.hostname or host.ip;
        user = host.sshUser or "deepwatrcreatur";
        description = host.description or "no description";
      in
      "# ${name} -> ${user}@${target} (${description})"
    ) sshHosts
  );

  # Generate matchBlocks from hosts
  matchBlocks = lib.mapAttrs (name: host: {
    hostname = host.hostname or host.ip;
    user = host.sshUser or "deepwatrcreatur";
  }) expandedSshHosts // {
    # Wildcard match block for default settings
    "*" = {
      userKnownHostsFile = "~/.ssh/known_hosts_dynamic ~/.ssh/known_hosts_managed";
      controlMaster = "auto";
      controlPersist = "15m";
      controlPath = "~/.ssh/master-%r@%n:%p";
    };
  };

in {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Global SSH settings
    extraConfig = ''
      # Global settings for all hosts
      # Inventory-backed SSH hosts:
      ${hostSummary}
      
      SendEnv LANG LC_* COLORTERM TERM_PROGRAM TERM_PROGRAM_VERSION
      ForwardX11 no
      ForwardAgent yes
      AddressFamily inet
      ServerAliveInterval 15
      ServerAliveCountMax 3
      ConnectTimeout 20
    '';

    # Generated host configurations
    inherit matchBlocks;
  };
}
