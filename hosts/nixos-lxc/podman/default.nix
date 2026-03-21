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
    ./modules/paperless-ngx.nix
    inputs.agenix.nixosModules.default
  ];

  networking.hostName = "podman";

  # Agenix secrets
  age.secrets."paperless-db-password" = {
    file = ../../secrets-agenix/paperless-db-password.age;
    owner = "root";
    group = "root";
    mode = "0440";
  };

  # Paperless-ngx service
  services.paperless-ngx = {
    enable = true;
    database = {
      user = "paperless_user"; # You can change this if you like
      passwordFile = config.age.secrets."paperless-db-password".path;
    };
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
