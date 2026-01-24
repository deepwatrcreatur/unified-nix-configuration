# modules/nixos/attic-post-build-hook.nix
#
# Compatibility shim.
#
# Prefer the upstream module from `inputs.nix-attic-infra` for the actual
# implementation. Keeping this file allows older host configs that import
# `modules/nixos/attic-post-build-hook.nix` to keep working.
{
  config,
  lib,
  inputs,
  ...
}:

{
  imports = [ inputs.nix-attic-infra.nixosModules.attic-post-build-hook ];
}
