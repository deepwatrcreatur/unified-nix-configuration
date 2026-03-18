{ config, lib, pkgs, ... }:

let
  remoteBuilder = import ../../../lib/remote-builder.nix { inherit pkgs; };
  hostName = config.networking.hostName or "";
  canUseRemoteBuilder = remoteBuilder.canUse hostName;
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
