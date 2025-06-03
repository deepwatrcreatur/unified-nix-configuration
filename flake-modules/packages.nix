# flake-modules/packages.nix
# This file will return the attribute set for the `packages` output.
# It needs access to `inputs` (for nixpkgs and lib) and your `overlays`.
{ inputs, lib, overlaysList }:

let
  # Define the systems to generate packages for
  # can also pass this in as an argument if preferred
  supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];

  # Helper to generate outputs for all supported systems
  forAllSystems = function: lib.genAttrs supportedSystems (system: function system);

in
forAllSystems (system:
  let
    pkgs = import inputs.nixpkgs {
      inherit system;
      config = nixpkgsConfig; # apply centralized config 
      overlays = overlaysList;       # Apply the provided list of overlays
    };
  in
  {
    # custom helix package
    helix-from-src = pkgs.helix-from-src;

    default = pkgs.helix-from-src; # Or simply 'self.helix-from-src' to refer to it within the set

    # can add other common packages to expose here
  }
)
