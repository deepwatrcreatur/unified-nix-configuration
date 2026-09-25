# den/aspects/service-scrypted.nix
# Scrypted video integration and camera bridge container stack aspect.
{ ... }:
{ ... }:
{
  imports = [
    ../../hosts/nixos-lxc/podman/stacks/scrypted-stack.nix
  ];
}
