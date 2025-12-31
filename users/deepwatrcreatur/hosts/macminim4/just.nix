# users/deepwatrcreatur/hosts/macminim4/just.nix
# Just module override for macminim4 with default justfile
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
