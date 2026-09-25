{ config, lib, pkgs, ... }:

let
  remoteBuilder = import ../../../lib/remote-builder.nix { inherit pkgs; };
  canUseRemoteBuilder = remoteBuilder.canUse config;
in
{
  config = lib.mkIf canUseRemoteBuilder {
    age.secrets.nix-remote-builder-key = {
      file = ../../../secrets-agenix/nix-remote-builder-key.age;
      path = remoteBuilder.keyPath;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };
}
