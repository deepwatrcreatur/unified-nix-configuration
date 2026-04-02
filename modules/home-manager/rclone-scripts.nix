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

    agenixRclonePath = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.local/share/agenix-user-secrets/rclone-conf";
      description = "Path to the decrypted agenix rclone config, if present.";
    };

    systemRclonePath = mkOption {
      type = types.str;
      default = "/run/secrets/rclone-conf";
      description = "Path to the system-provisioned rclone config, if present.";
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

      mkdir -p "$HOME/.config/rclone"

      # Prefer the Home Manager agenix secret if present, otherwise fall back to
      # the system-provisioned secret, and finally the legacy SOPS-encrypted secret.
      SECRETS_PATH="${toString cfg.secretsPath}"
      RCLONE_ENC="$SECRETS_PATH/rclone.conf.enc"
      AGENIX_RCLONE="${cfg.agenixRclonePath}"
      SYSTEM_RCLONE="${cfg.systemRclonePath}"
      TARGET_RCLONE="$HOME/.config/rclone/rclone.conf"

      if [ -f "$AGENIX_RCLONE" ]; then
        install -m 600 "$AGENIX_RCLONE" "$TARGET_RCLONE"
      elif [ -f "$SYSTEM_RCLONE" ] && [ -r "$SYSTEM_RCLONE" ]; then
        install -m 600 "$SYSTEM_RCLONE" "$TARGET_RCLONE"
      elif [ -f "$RCLONE_ENC" ]; then
        if [ -f "$SOPS_AGE_KEY_FILE" ]; then
          tmp_rclone="$(mktemp)"
          if sops -d "$RCLONE_ENC" > "$tmp_rclone" 2>/dev/null; then
            install -m 600 "$tmp_rclone" "$TARGET_RCLONE"
          fi
          rm -f "$tmp_rclone"
        else
          echo "Warning: SOPS age key not found at $SOPS_AGE_KEY_FILE, skipping rclone secrets decryption"
        fi
      else
        echo "Warning: no agenix or SOPS rclone config found; leaving existing rclone.conf in place"
      fi
    '';
  };
}
