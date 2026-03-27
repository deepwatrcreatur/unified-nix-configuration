{
  inputs,
  ...
}:
{
  imports = [
    ../../../modules/nixos/common
    ../../../modules/nixos/lxc-common.nix
    ../../../modules/nixos/attic-client.nix
    ../../../modules/nixos/nix-daemon-user-ssh.nix
    ../../../modules/nixos/container-stack.nix  # New container stack module
    ./stacks/plex-stack.nix
    ./stacks/paperless-stack.nix  # Simplified stack config
    ./stacks/nightscout-stack.nix  # CGM remote monitoring
    ./stacks/librelinkup-stack.nix  # LibreLinkUp to Nightscout bridge
    inputs.agenix.nixosModules.default
  ];

  networking.hostName = "podman";

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune.enable = true;
  };

  # LXC common configuration
  lxc = {
    enable = true;

    users.extraGroups = [ "wheel" "podman" ];

    homeManager = {
      enable = true;
      primaryUserImports = [
        ../../../users/deepwatrcreatur/hosts/podman
      ];
    };

    services = {
      sshKeysManager = true;
      atticClient = true;
      nixDaemonUserSsh = true;
    };

    agenix = {
      machineIdentity = true;
      atticToken = true;
    };
  };
}
