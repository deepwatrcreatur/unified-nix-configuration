{ config, lib, inputs, ... }:

{
  imports = [
    inputs.ssh-keys-manager.nixosModules.default
  ];

  # Note: The per-host NixOS config must set services.ssh-keys-manager.username
  # in order for the keys to be mapped to a specific user.
  services.ssh-keys-manager = {
    enable = true;
    keysDirectory = ../../../ssh-keys;
    enableDynamicKeys = true;
  };
}
