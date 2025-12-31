{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}
