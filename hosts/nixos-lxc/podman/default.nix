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
    inputs.agenix.nixosModules.default
    inputs.arion.nixosModules.arion
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

  # Arion configuration for Podman
  virtualisation.arion = {
    backend = "podman-socket";
    projects.paperless.settings = {
      imports = [ ./stacks/paperless-arion.nix ];
    };
  };

  # Agenix secrets for paperless
  age.secrets."paperless-db-password" = {
    file = ../../../secrets-agenix/paperless-db-password.age;
    owner = "root";
    group = "root";
    mode = "0440";
  };

  # Create persistent data directories for Paperless-ngx
  systemd.tmpfiles.rules = [
    "d /var/lib/paperless/consume 0777 root root -"
    "d /var/lib/paperless/data 0777 root root -"
    "d /var/lib/paperless/pgdata 0777 root root -"
  ];

  # Open firewall port for Paperless-ngx
  networking.firewall.allowedTCPPorts = [ 8000 ];
}
