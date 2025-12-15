{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.rclone-scripts;
in
{
  options.programs.rclone-scripts = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable rclone with sync scripts for cloud storage";
    };

    secretsPath = mkOption {
      type = types.path;
      description = "Path to the secrets directory for rclone config";
    };
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

    home.activation.rcloneSecretsActivation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
      export PATH="${lib.makeBinPath [ pkgs.sops ]}:$PATH"

      # Decrypt rclone.conf
      mkdir -p "$HOME/.config/rclone"
      rm -f "$HOME/.config/rclone/rclone.conf"
      sops -d "${toString cfg.secretsPath}/rclone.conf.enc" > "$HOME/.config/rclone/rclone.conf"
      chmod 600 "$HOME/.config/rclone/rclone.conf"
    '';
  };
}