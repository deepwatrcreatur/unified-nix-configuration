{
  inputs,
  ...
}:
{
  imports = [
    ../../../modules/nixos/common # Common NixOS modules including ssh-keys-manager
    ../../../modules/nixos/lxc-common.nix
    ../../../modules/nixos/attic-client.nix
    ../../../modules/nixos/nix-daemon-user-ssh.nix
    ./modules/containers.nix
    ./stacks/paperless-quadlet.nix
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
