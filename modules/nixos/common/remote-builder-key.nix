{ config, lib, pkgs, ... }:

let
  remoteBuilderSupportedHosts = [
    "gateway"
    "homeserver"
    "workstation"
  ];
  hostName = config.networking.hostName or "";
  canUseRemoteBuilder = hostName != "attic-cache" && builtins.elem hostName remoteBuilderSupportedHosts;
  remoteBuilderKeyPath = if pkgs.stdenv.isDarwin then "/var/root/.ssh/nix-remote" else "/root/.ssh/nix-remote";
in
{
  config = lib.mkIf canUseRemoteBuilder {
    age.secrets.nix-remote-builder-key = {
      file = ../../../secrets-agenix/nix-remote-builder-key.age;
      path = remoteBuilderKeyPath;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };
}
