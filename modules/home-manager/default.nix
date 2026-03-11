# modules/home-manager/default.nix
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  # Auto-import all .nix files and directories from common directory
  commonDir = ./common;
  commonImports = lib.mapAttrsToList (name: _: commonDir + "/${name}") (
    lib.filterAttrs
      (name: type: (type == "regular" && lib.hasSuffix ".nix" name) || type == "directory")
      (builtins.readDir commonDir)
  );

  hasZellijVividRounded = inputs ? zellij-vivid-rounded;
in
{
  imports =
    commonImports
    ++ lib.optionals hasZellijVividRounded [
      inputs.zellij-vivid-rounded.homeManagerModules.default
    ];

  # Copy .terminfo files into place
  home.file.".terminfo" = {
    source = ../../modules/home-manager/terminfo;
    recursive = true;
  };
  home.file.".ssh/config".source = ./ssh-config;
  
  # Hybrid known_hosts: Use activation script to create mutable file
  # Can't use home.file because it creates immutable nix store symlink
  home.activation.setupDynamicKnownHosts = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Create mutable known_hosts_dynamic if it doesn't exist
    if [[ ! -f ~/.ssh/known_hosts_dynamic ]] || [[ -L ~/.ssh/known_hosts_dynamic ]]; then
      $DRY_RUN_CMD rm -f ~/.ssh/known_hosts_dynamic
      $DRY_RUN_CMD touch ~/.ssh/known_hosts_dynamic
      $DRY_RUN_CMD chmod 600 ~/.ssh/known_hosts_dynamic
      echo "Created mutable known_hosts_dynamic"
    fi
  '';
  
  home.activation.migrateKnownHosts = lib.hm.dag.entryAfter ["setupDynamicKnownHosts"] ''
    # One-time migration: move existing known_hosts to known_hosts_dynamic
    if [[ -f ~/.ssh/known_hosts ]] && [[ ! -f ~/.ssh/known_hosts.migrated ]]; then
      $DRY_RUN_CMD cat ~/.ssh/known_hosts >> ~/.ssh/known_hosts_dynamic
      $DRY_RUN_CMD mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bak
      $DRY_RUN_CMD touch ~/.ssh/known_hosts.migrated
      echo "Migrated existing known_hosts to known_hosts_dynamic"
    fi
  '';
  
  programs.home-manager.enable = true;
}
