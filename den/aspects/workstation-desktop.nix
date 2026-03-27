# Shared desktop aspect for workstation-class machines.
# Imports the workstation profile which covers GNOME, AMD GPU, audio,
# printing, attic-client, nixbit, snap, and all system packages.
# Hardware (hardware-configuration.nix + networking.nix) is injected
# via extraImports in each leaf host's mkHostModule call.
{ ... }:
{ ... }:
{
  imports = [
    ../../profiles/nixos/workstation.nix
  ];
}
