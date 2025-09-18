# users/deepwatrcreatur/hosts/inference-node/just.nix
# Override for hostname detection - the system hostname is "inference-node1"
# but our directory is "inference-node"
{ config, pkgs, lib, ... }:

{
  home.packages = [ pkgs.just ];

  # Create the justfile symlink pointing to the local justfile
  home.file.".justfile".source = ./justfile;
}