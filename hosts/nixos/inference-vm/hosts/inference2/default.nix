{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Legacy path: the active `.#inference2` output is built from `den/hosts`
  # and den aspects. Keep this file only as migration context while the old
  # inference host tree still exists. Do not land active inference2 fixes here
  # first.
  imports = [
    ./hardware-configuration.nix

    # Import common inference VM configuration
    ../..
  ];

  boot.growPartition = true;

  # Host-specific configuration
  networking.hostName = "inference2";
}
