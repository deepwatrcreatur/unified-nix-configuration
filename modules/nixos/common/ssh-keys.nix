{ config, lib, inputs, ... }:

{
  imports = [
    inputs.ssh-keys-manager.nixosModules.default
    inputs.ssh-keys-manager.nixosModules.ssh-known-hosts
    inputs.ssh-keys-manager.nixosModules.ssh-remote-builder-keys
  ];

  # Note: The per-host NixOS config must set services.ssh-keys-manager.username
  # in order for the keys to be mapped to a specific user.
  services.ssh-keys-manager = {
    enable = true;
    keysDirectory = ../../../ssh-keys;
    enableDynamicKeys = true;
  };

  programs.ssh-known-hosts-manager = {
    enable = true;
    keysDirectory = ../../../ssh-keys;
    sshConfigFile = ../../../modules/home-manager/ssh-config;
  };

  # Deploy SSH private key for nix remote builder authentication
  # The key is deployed to /root/.ssh/nix-remote, matching nix-settings.nix config
  services.ssh-remote-builder-keys = {
    enable = true;
    keyName = "nix-remote";
    sopsFile = ../../../secrets/nix-remote-builder-key.yaml.enc;
    sopsKey = "private_key";
  };
}
