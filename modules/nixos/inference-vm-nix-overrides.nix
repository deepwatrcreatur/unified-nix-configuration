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

  # The common nix-settings module now derives nix-daemon's NIX_CONFIG from the
  # final merged nix.settings.experimental-features value, so no separate daemon
  # environment override is needed here.
} 
