{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.rclone;
in
{
  options.programs.rclone = {
    enable = mkEnableOption "rclone";

    filterFile = mkOption {
      type = types.path;
      description = "Path to the rclone filter file.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.rclone ];

    home.file.".config/rclone/filter.txt" = {
      source = cfg.filterFile;
    };
  };
}