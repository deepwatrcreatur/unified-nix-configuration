# modules/nixos/attic-observatory.nix
#
# Compatibility shim.
#
# Prefer the upstream module from `inputs.nix-attic-infra` for the actual
# implementation. Keeping this file allows host configs to depend on the
# repository-local path while the implementation lives in nix-attic-infra.
{
  inputs,
  ...
}:

{
  imports = [ inputs.nix-attic-infra.nixosModules.attic-observatory ];
}
