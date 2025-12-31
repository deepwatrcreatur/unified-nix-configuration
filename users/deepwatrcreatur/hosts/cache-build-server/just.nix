# users/deepwatrcreatur/hosts/cache-build-server/just.nix
# Just module override for cache-build-server with custom justfile
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Import of unified just module with platform auto-detection
  imports = [ ../../../../modules/home-manager/common/just.nix ];

  # Override with host-specific justfile
  home.file.".justfile".source = ./justfile;
}
