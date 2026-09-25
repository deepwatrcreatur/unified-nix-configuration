# users/deepwatrcreatur/hosts/workstation/default.nix
# Workstation profile leaf — composed from reusable user aspects.
{ ... }:
{
  imports = [
    ../../aspects/developer.nix
    ../../aspects/desktop-whitesur.nix
  ];

  home.stateVersion = "24.11";
}
