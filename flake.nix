{
  description = "Minimal flake-parts Darwin/NixOS config (no perSystem)";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/24.11";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # Add other inputs as needed (home-manager, sops-nix, etc.)
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake {
      inherit inputs;
      systems = [ "aarch64-darwin" "x86_64-linux" ];
    } {
      imports = [
        ./flake-parts/hosts/macminim4.nix
        ./flake-parts/hosts/homeserver.nix
        # ./flake-parts/hosts/inference1.nix
        # (add more as needed)
      ];
  };
}
