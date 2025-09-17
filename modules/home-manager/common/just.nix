# modules/home-manager/common/just.nix
{ config, pkgs, lib, ... }:
let
  # Get the username from config
  username = config.home.username;

  # Get the hostname - try from config first, fallback to environment
  hostname = config.networking.hostName or (builtins.getEnv "HOSTNAME");

  # Path to the host-specific justfile
  justfilePath = ../../users/${username}/hosts/${hostname}/justfile;

  # Check if the host-specific justfile exists
  hostJustfileExists = builtins.pathExists justfilePath;

  # Fallback to user-level justfile if host-specific doesn't exist
  userJustfilePath = ../../users/${username}/justfile;
  userJustfileExists = builtins.pathExists userJustfilePath;
in
{
  home.packages = [ pkgs.just ];

  # Only create the symlink if a justfile exists
  home.file.".justfile" = lib.mkIf (hostJustfileExists || userJustfileExists) {
    source = if hostJustfileExists then justfilePath else userJustfilePath;
  };
}