# den/aspects/service-librelinkup.nix
# LibreLinkUp glucose integration container stack aspect.
{ ... }:
{ ... }:
{
  imports = [
    ../../hosts/nixos-lxc/podman/stacks/librelinkup-stack.nix
  ];
}
