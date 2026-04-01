let
  flake = (import ./flake.nix);
  # Mock inputs roughly
  inputs = {
    nixpkgs = <nixpkgs>;
  };
  checks = import ./outputs/checks.nix {
    inherit inputs;
    commonNixpkgsConfig = {};
    commonOverlays = [];
  };
in
  checks.checks.x86_64-linux.inventory-consistency
