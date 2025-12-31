# users/deepwatrcreatur/hosts/inference-node/just.nix
# Custom justfile for inference-node (overrides unified module)
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
