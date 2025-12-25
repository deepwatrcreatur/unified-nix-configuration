# modules/home-manager/common/comma.nix
{ inputs, ... }:

{
  imports = [
    inputs.nix-index-database.homeModules.nix-index
  ];

  # This replaces the need for programs.comma.enable = true;
  # as it configures both nix-index and comma together.
  programs.nix-index-database.comma.enable = true;
  programs.nix-index.enable = true;
}
