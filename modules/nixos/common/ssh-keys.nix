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
  sshConfigFile = pkgs.writeText "ssh-config-generated" sshConfigContent;

in {
  imports = [
    inputs.ssh-keys-manager.nixosModules.default
    inputs.ssh-keys-manager.nixosModules.ssh-known-hosts
  ];

  services.ssh-keys-manager = {
    enable = true;
    username = lib.mkDefault config.host.primaryUser;
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
