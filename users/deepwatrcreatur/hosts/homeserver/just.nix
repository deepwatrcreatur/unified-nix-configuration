# users/deepwatrcreatur/hosts/homeserver/just.nix
# Just module override for homeserver with default justfile
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Import of unified just module with platform auto-detection
  imports = [ ../../../../modules/home-manager/common/just.nix ];
  # Override with default justfile (no custom commands)
  home.file.".justfile".source = ./justfile;
}
