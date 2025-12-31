# users/deepwatrcreatur/hosts/inference-vm/just.nix
# Just module override for inference-vm with custom justfile
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
