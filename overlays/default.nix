# overlays/default.nix
# Combines all overlays into a single list for use in flake.nix
{ inputs, commonNixpkgsConfig, nixpkgsLib }:

let
  # Import individual overlay modules
  stableOverlay = import ./stable.nix { inherit inputs commonNixpkgsConfig; };
  cosmicOverlay = import ./cosmic.nix { inherit inputs commonNixpkgsConfig; };
  packagesOverlay = import ./packages.nix { inherit nixpkgsLib; };
  flakeInputsOverlay = import ./flake-inputs.nix { inherit inputs; };
in
# Order matters: later overlays can override earlier ones
stableOverlay
++ cosmicOverlay
++ packagesOverlay
++ flakeInputsOverlay
