# modules/home-manager/common/comma.nix
{ inputs, lib, ... }:
let
  hasNixIndexDatabase = inputs ? nix-index-database;
in
{
  imports = lib.optionals hasNixIndexDatabase [
    inputs.nix-index-database.homeModules.nix-index
  ];

  # Enable nix-index shell integration and search database
  programs.nix-index.enable = true;

  # Enable comma with pre-indexed database from nix-index-database
  programs.nix-index-database.comma.enable = lib.mkIf hasNixIndexDatabase true;
}

