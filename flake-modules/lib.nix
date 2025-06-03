# flake-modules/lib.nix
{ inputs }: # Takes flake inputs as an argument
let
  # Lib from the primary nixpkgs input for convenience
  nixpkgsLib = inputs.nixpkgs.lib;

  # Helper to import modules from a directory
  importModules = path:
    let
      dirContents = builtins.readDir path;
      nixFiles = nixpkgsLib.filterAttrs (name: type:
        type == "regular" && nixpkgsLib.strings.hasSuffix ".nix" name
      ) dirContents;
    in
    nixpkgsLib.mapAttrsToList (name: _: path + "/${name}") nixFiles;

  # --- Overlays ---
  helixOverlay = import ../overlays/helix.nix;

  # List of all overlays to be applied consistently across systems/packages
  
  allOverlays = [
    helixOverlay 
  ];

  # --- Centralized Nixpkgs Configuration ---
  nixpkgsConfig = {
    allowUnfree = true;
    # can add other global nixpkgs config options here if needed
    # e.g., permittedInsecurePackages = [ "some-package-1.2.3" ];
  };
  
in
{
  # Expose nixpkgs.lib for use in other flake modules and flake.nix itself
  lib = nixpkgsLib;

  # Expose the combined list of overlays
  inherit importModules allOverlays nixpkgsConfig;
  
  # Centralize the list of supported systems
  supportedSystems = [ "x86_64-linux" "aarch64-darwin" ];
}
