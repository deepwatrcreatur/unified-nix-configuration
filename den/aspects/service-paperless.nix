# den/aspects/service-paperless.nix
# Paperless-ngx document indexing and management container stack aspect.
{ ... }:
{ ... }:
{
  imports = [
    ../../hosts/nixos-lxc/podman/stacks/paperless-stack.nix
  ];
}
