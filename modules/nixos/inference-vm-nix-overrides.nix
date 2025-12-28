{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Inference VM specific nix settings to work around determinate nix cgroups issues
  # Override the common nix-settings for inference VMs that use determinate nix

  nix.settings = {
    experimental-features = lib.mkForce [
      "nix-command"
      "flakes"
      "impure-derivations"
      "ca-derivations"
      "pipe-operators"
      # Exclude cgroups to fix determinate nix compatibility
    ];
    use-cgroups = lib.mkForce false;
  };

  # Override systemd service environment to exclude cgroups
  systemd.services.nix-daemon.environment.NIX_CONFIG = lib.mkForce "experimental-features = nix-command flakes impure-derivations ca-derivations pipe-operators";
}