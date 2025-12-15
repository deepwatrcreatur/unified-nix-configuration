{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.rclone-scripts;
in
{
  options.programs.rclone-scripts = {
    enable = mkEnableOption "rclone with sync scripts for cloud storage";
  };

  config = mkIf cfg.enable {
    programs.rclone.enable = true;

    home.file.".config/rclone/filter.txt" = {
      source = ./rclone-filter.txt;
    };

    home.packages = with pkgs; [
      (writeShellScriptBin "onedrive-sync" ''
        #!/bin/bash
        if [ $# -ne 2 ]; then
            echo "Usage: $0 <local_dir> <remote_dir>"
            exit 1
        fi
        rclone sync "$1" "OneDrive:$2" --progress --verbose --metadata --filter-from ~/.config/rclone/filter.txt
      '')
      (writeShellScriptBin "mega-rclone" ''
        #!/bin/bash
        if [ $# -ne 2 ]; then
            echo "Usage: $0 <local_dir> <remote_dir>"
            exit 1
        fi
        rclone sync "$1" "mega:$2" --progress --verbose --metadata --filter-from ~/.config/rclone/filter.txt
      '')
    ];
  };
}