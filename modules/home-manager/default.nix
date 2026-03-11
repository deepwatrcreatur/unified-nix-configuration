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
  
  # Hybrid known_hosts: Create empty dynamic file for SSH to populate
  home.file.".ssh/known_hosts_dynamic" = {
    text = "# Dynamic known_hosts - SSH will write new host keys here\n";
    # Don't force - let SSH append to it
  };
  
  home.activation.migrateKnownHosts = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # One-time migration: move existing known_hosts to known_hosts_dynamic
    if [[ -f ~/.ssh/known_hosts ]] && [[ ! -f ~/.ssh/known_hosts.migrated ]]; then
      $DRY_RUN_CMD mv -v ~/.ssh/known_hosts ~/.ssh/known_hosts_dynamic
      $DRY_RUN_CMD touch ~/.ssh/known_hosts.migrated
      echo "Migrated existing known_hosts to known_hosts_dynamic"
    fi
  '';
  
  programs.home-manager.enable = true;
}
