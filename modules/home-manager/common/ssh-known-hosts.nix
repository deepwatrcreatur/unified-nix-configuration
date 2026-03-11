# modules/home-manager/common/ssh-known-hosts.nix
# Manages known SSH host keys for common infrastructure
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    inputs.ssh-keys-manager.homeManagerModules.default
  ];

  programs.ssh-known-hosts-manager = {
    enable = true;
    keysDirectory = ../../../ssh-keys;
    sshConfigFile = ../ssh-config;
  };
}
