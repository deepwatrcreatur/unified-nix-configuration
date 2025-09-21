# modules/home-manager/common/just.nix
{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.myModules.just;
  username = config.home.username;

  # Path to the host-specific justfile, using the declarative hostname
  # An empty hostname is valid, in which case we'll just use the user-level fallback
  justfilePath = if cfg.hostname != "" then
    ../../users/${username}/hosts/${cfg.hostname}/justfile
  else
    # This path is intentionally invalid to make the check fail
    "/path/to/non-existent/justfile";
  hostJustfileExists = builtins.pathExists justfilePath;

  # Fallback to user-level justfile
  userJustfilePath = ../../users/${username}/justfile;
  userJustfileExists = builtins.pathExists userJustfilePath;
in
{
  options.myModules.just = {
    enable = mkEnableOption "just";

    hostname = mkOption {
      type = types.str;
      default = "";
      description = "The hostname of the system, used to find the host-specific justfile.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.just ];

    # Only create the symlink if a justfile exists
    home.file.".justfile" = mkIf (hostJustfileExists || userJustfileExists) {
      source = if hostJustfileExists then justfilePath else userJustfilePath;
    };
  };
}