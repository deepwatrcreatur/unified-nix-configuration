{ config, lib, inputs, ... }:

{
  imports = [
    inputs.ssh-keys-manager.nixosModules.default
  ];

  services.ssh-keys-manager = {
    enable = true;
    keysDirectory = ../../../ssh-keys;
    username = "deepwatrcreatur";
    enableDynamicKeys = true;
  };
}
