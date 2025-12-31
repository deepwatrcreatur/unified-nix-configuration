{
  lib,
  ...
}:

{
  # Fix for determinate nix daemon experimental features
  # This must be in a NixOS-specific module to avoid issues on nix-darwin
  systemd.services.nix-daemon.environment.NIX_CONFIG =
    lib.mkForce "experimental-features = nix-command flakes impure-derivations ca-derivations pipe-operators cgroups";
}
