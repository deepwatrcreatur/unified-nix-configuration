# modules/home-manager/common/ssh-config.nix
# Generates SSH config from lib/hosts.nix - single source of truth
{ config, lib, pkgs, ... }:

let
  hostsData = import ../../../lib/hosts.nix;

  # Filter hosts that should be in SSH config
  sshHosts = lib.filterAttrs (name: host:
    (host.includeSsh or true)
    && ((host.sshHostname or null) != null || (host.hostname or null) != null || (host.ip or null) != null)
  ) hostsData.hosts;

  hostSummary = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: host:
      let
        target = host.sshHostname or host.hostname or host.ip;
        user = host.sshUser or "deepwatrcreatur";
        description = host.description or "no description";
      in
      "# ${name} -> ${user}@${target} (${description})"
    ) sshHosts
  );

  # Generate SSH host blocks from hosts using upstream OpenSSH directive names.
  # WHY: one block per machine, with its aliases as extra Host patterns. One
  # block per alias made host pickers such as sshs list a machine once per
  # name (emerald showed up as attic-cache, cache, nix-cache and tomahawk).
  sshSettings =
    lib.mapAttrs (name: host: {
      header = "Host ${lib.concatStringsSep " " ([ name ] ++ (host.aliases or [ ]))}";
      HostName = host.sshHostname or host.hostname or host.ip;
      User = host.sshUser or "deepwatrcreatur";
    }) sshHosts
    // {
      "*" = {
        UserKnownHostsFile = "~/.ssh/known_hosts_dynamic ~/.ssh/known_hosts_managed";
        ControlMaster = "auto";
        ControlPersist = "15m";
        ControlPath = "~/.ssh/master-%r@%n:%p";
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

    settings = sshSettings;
  };

  # OpenSSH rejects the Home Manager symlink at ~/.ssh/config on this host.
  # Keep using programs.ssh for rendering, then materialize a real 0600 file
  # after HM writes the generation links.
  home.file.".ssh/config".force = true;

  home.activation.materializeSshConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.ssh"
    config_path="$HOME/.ssh/config"

    if [ -L "$config_path" ]; then
      source_path="$(${pkgs.coreutils}/bin/readlink -f "$config_path")"
      tmp_path="$HOME/.ssh/config.hm-tmp"

      $DRY_RUN_CMD ${pkgs.coreutils}/bin/cp "$source_path" "$tmp_path"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 600 "$tmp_path"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$tmp_path" "$config_path"
      echo "Materialized ~/.ssh/config as a regular file for OpenSSH"
    elif [ -f "$config_path" ]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 600 "$config_path"
    fi
  '';
}
