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
    inputs.ssh-keys-manager.nixosModules.default
    inputs.ssh-keys-manager.nixosModules.ssh-known-hosts
  ];

  # Note: The per-host NixOS config must set services.ssh-keys-manager.username
  # in order for the keys to be mapped to a specific user.
  services.ssh-keys-manager = {
    enable = true;
    keysDirectory = ../../../ssh-keys;
    enableDynamicKeys = true;

    # Include stable operator identity key on all hosts using this module.
    extraAuthorizedKeys =
      let
        stableIdentityPath = ../../../ssh-keys/deepwatrcreatur-stable-identity.pub;
      in
      lib.optionals (builtins.pathExists stableIdentityPath) [
        (lib.strings.trim (builtins.readFile stableIdentityPath))
      ];
  };

  programs.ssh-known-hosts-manager = {
    enable = true;
    keysDirectory = ../../../ssh-keys;
    sshConfigFile = sshConfigFile;
  };
}
