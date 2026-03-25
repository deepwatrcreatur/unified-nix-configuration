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
    ./modules/containers.nix
    ./stacks/paperless-stack.nix  # Simplified stack config
    ./stacks/nightscout-stack.nix  # CGM remote monitoring
    inputs.agenix.nixosModules.default
  ];

  networking.hostName = "podman";

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
