# overlays/cosmic.nix
# COSMIC desktop packages from nixpkgs-unstable
{ inputs, commonNixpkgsConfig }:

[
  # Prefer COSMIC packages from nixpkgs-unstable (Dec 11 fixes)
  (final: prev: {
    inherit
      (import inputs.nixpkgs-unstable {
        system = prev.stdenv.hostPlatform.system;
        config = commonNixpkgsConfig;
      })
      xdg-desktop-portal-cosmic
      cosmic-greeter
      cosmic-panel
      cosmic-applets
      cosmic-icons
      cosmic-settings
      cosmic-term
      cosmic-store
      cosmic-files
      cosmic-randr
      cosmic-edit
      cosmic-screenshot
      cosmic-bg
      cosmic-comp
      cosmic-session
      ;
  })
]
