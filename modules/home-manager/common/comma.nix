# modules/home-manager/common/comma.nix
{ inputs, lib, ... }:
let
  hasNixIndexDatabase = inputs ? nix-index-database;
in
{
  imports = lib.optionals hasNixIndexDatabase [
    inputs.nix-index-database.homeModules.nix-index
  ];

  programs.nix-index.enable = true;
}
// lib.optionalAttrs hasNixIndexDatabase {
  # This replaces the need for programs.comma.enable = true;
  # as it configures both nix-index and comma together.
  programs.nix-index-database.comma.enable = true;
}
