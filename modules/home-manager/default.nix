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
  programs.home-manager.enable = true;
}
