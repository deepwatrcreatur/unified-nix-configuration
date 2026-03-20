# overlays/stable.nix
# Overlays for using stable packages when unstable causes issues
{ inputs, commonNixpkgsConfig }:

[
  # Generic stable package import helper
  (final: prev:
    let
      stable = import inputs.nixpkgs-stable {
        system = prev.stdenv.hostPlatform.system;
        config = commonNixpkgsConfig;
      };
    in
    {
      # Add stable packages here when needed to avoid compilation
      # Example: some-package = stable.some-package;
    }
  )

  # Tailscale from stable
  (final: prev: {
    inherit (inputs.nixpkgs-stable.legacyPackages.${prev.stdenv.hostPlatform.system}) tailscale;
  })

  # Fish shell fix (disable tests)
  (final: prev: {
    fish = prev.fish.overrideAttrs (oldAttrs: {
      doCheck = false;
    });
  })
]
