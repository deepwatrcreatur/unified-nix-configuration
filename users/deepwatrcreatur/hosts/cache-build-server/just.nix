# users/deepwatrcreatur/hosts/cache-build-server/just.nix
# Custom justfile for cache-build-server (overrides unified module)
{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = [ pkgs.just ];
  # Use host-specific custom justfile instead of unified module
  home.file.".justfile".source = ./justfile;
}
