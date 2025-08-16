{
  description = "Unified NixOS configuration for multiple hosts";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    omarchy-nix = {
      url = "github:henrysipp/omarchy-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    garuda = {
      url = "gitlab:garuda-linux/garuda-nix-subsystem/stable";
      # Note: GNS follows their own nixpkgs for caching benefits
      # Don't override their nixpkgs input unless necessary
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nix-darwin, hyprland, omarchy-nix, garuda, ... }:
  let
    # Helper function to create system configurations
    mkSystem = { system, modules }: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs self; };
      modules = modules ++ [
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
          };
        }
      ];
    };

    # Helper function for Garuda systems using their lib
    mkGarudaSystem = { system, modules }: garuda.lib.garudaSystem {
      inherit system;
      modules = modules ++ [
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
          };
        }
      ];
    };

    inputs = { inherit nixpkgs nixpkgs-unstable home-manager nix-darwin hyprland omarchy-nix garuda; };
  in
  {
    nixosConfigurations = {
      # Your existing hosts (adjust these to match your current setup)
      homeserver = mkSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixos/homeserver
          ./hosts/common-nixos.nix
        ];
      };

      inference1 = mkSystem {
        system = "x86_64-linux"; 
        modules = [
          ./hosts/nixos/inference1
          ./hosts/common-nixos.nix
          ./modules/nixos/common-inference-vm.nix
        ];
      };

      inference2 = mkSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixos/inference2
          ./hosts/common-nixos.nix
          ./modules/nixos/common-inference-vm.nix
        ];
      };

      inference3 = mkSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixos/inference3
          ./hosts/common-nixos.nix
          ./modules/nixos/common-inference-vm.nix
        ];
      };

      omarchy-nix = mkSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixos/omarchy-nix
          ./hosts/common-nixos.nix
          omarchy-nix.nixosModules.default
        ];
      };

      garuda-nix = mkGarudaSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixos/garuda-nix
          # Note: Don't include common-nixos.nix here as Garuda provides its own base
        ];
      };
    };

    darwinConfigurations = {
      macminim4 = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs self; };
        modules = [
          ./hosts/macminim4
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
            };
          }
        ];
      };
    };

    # Development shell for managing the flake
    devShells = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ] (system:
      let pkgs = nixpkgs.legacyPackages.${system}; in
      pkgs.mkShell {
        buildInputs = with pkgs; [
          nixos-rebuild
          home-manager
          git
        ];
      }
    );
  };
}
