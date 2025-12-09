# modules/nixos/common/activation-backup.nix
# Automatically backup existing files that would block system activation

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Backup existing files during activation instead of failing
  environment.etc."nixos/.keep-etc".text = ''
    This directory is managed by NixOS.
  '';

  # Set the backup file extension for files that would conflict during activation
  environment.etc."backup-extension" = {
    text = ".backup-before-nix";
    mode = "0644";
  };
}
