# modules/home-manager/common/just.nix
{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.myModules.just;
  username = config.home.username;
  flakeRoot = ../../..; # This will resolve to the flake's root directory

  # Path to the host-specific justfile, using the declarative hostname
  justfilePath = if cfg.hostname != "" then
    "${flakeRoot}/users/${username}/hosts/${cfg.hostname}/justfile"
  else
    null;
  hostJustfileExists = if justfilePath != null then builtins.pathExists justfilePath else false;

  # Fallback to user-level justfile
  userJustfilePath = "${flakeRoot}/users/${username}/justfile";
  userJustfileExists = builtins.pathExists userJustfilePath;
in
(lib.trace "just.nix: username=${username}, hostname=${cfg.hostname}, flakeRoot=${toString flakeRoot}, justfilePath=${toString justfilePath}, hostJustfileExists=${toString hostJustfileExists}" {
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
})