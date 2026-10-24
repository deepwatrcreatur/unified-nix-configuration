# den/aspects/orca-ide.nix
# Orca - The Agent Development Environment (ADE) for coding agents (https://www.onorca.dev/)
{ ... }:
{ lib, ... }:
{
  imports = [
    ../../modules/nixos/orca-ide.nix
  ];

  modules.desktop.apps.orca-ide.enable = lib.mkDefault true;
}
