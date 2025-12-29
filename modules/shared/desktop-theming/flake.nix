{
  description = "Modular desktop theming system for NixOS with macOS-like appearance";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # Supported systems
      systems = [ "x86_64-linux" "aarch64-linux" ];

      # Helper to generate attrs for each system
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      # NixOS modules for system-level configuration
      nixosModules = {
        # Core options module - define desktopTheming.* options
        default = import ./default.nix;

        # Package installer - installs theme packages based on options
        packages = import ./packages.nix;
      };

      # Home Manager modules for user-level configuration
      homeManagerModules = {
        # GTK/Qt theming for Home Manager
        default = import ./home.nix;

        # Desktop environment adapters
        cinnamon = import ./desktops/cinnamon.nix;
        gnome = import ./desktops/gnome.nix;
      };

      # Overlay for custom packages (if needed in the future)
      overlays.default = final: prev: { };

      # Package set for each system (currently empty, for future theme packages)
      packages = forAllSystems (system: { });

      # Development shell
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            name = "desktop-theming-dev";
            packages = with pkgs; [
              nixpkgs-fmt
              statix
            ];
          };
        }
      );
    };
}
