# flake.nix
{
  description = "Multi-system Nix configurations (NixOS, nix-darwin, Home Manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager"; 
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    helix.url = "github:helix-editor/helix";
    helix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ ... }:
  let
    # Standard library from nixpkgs - this is the "pure" lib
    nixpkgsLib = inputs.nixpkgs.lib;

    commonNixpkgsConfig = {
      allowUnfree = true;
    };
    commonOverlays = [];

    # SpecialArgs for NixOS and Darwin SYSTEM modules.
    # These modules can safely receive the pure nixpkgsLib.
    systemSpecialArgs = { inherit inputs; lib = nixpkgsLib; };

    # SpecialArgs specifically for HOME MANAGER modules.
    # We only pass 'inputs'. Home Manager will provide its own 'lib' and 'config.lib'.
    homeManagerModuleArgs = { inherit inputs; };
# Helper to import all .nix files from a directory as module paths.
    importAllModulesInDir = dir:
      let
        items = builtins.readDir dir;
        isNixFile = name: type: type == "regular" && lib.hasSuffix ".nix" name;
        nixFileNames = lib.attrNames (lib.filterAttrs isNixFile items);
      in
        map (fileName: dir + "/${fileName}") nixFileNames;
  in
  {
    # --- Home Manager Configurations (Standalone) ---
    homeConfigurations = {
      proxmox-root = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux"; 
          config = commonNixpkgsConfig;
          overlays = commonOverlays;
        };
        # Use the carefully crafted args for Home Manager modules
        extraSpecialArgs = homeManagerModuleArgs;
        modules = [
          ./users/root/hosts/proxmox 
          ./modules/home-manager     
        ];
      };
    };

    # --- Darwin Configurations ---
    darwinConfigurations.macminim4 = inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = systemSpecialArgs; # For Darwin system modules
      modules = [
        {
          nixpkgs.overlays = commonOverlays;
          nixpkgs.config = commonNixpkgsConfig;
        }
        ./modules
        ./hosts/macminim4
        inputs.home-manager.darwinModules.home-manager # The HM darwin module
        # Anonymous module to configure HM user and pass correct extraSpecialArgs
        ({ pkgs, config, lib, inputs, ... }: {
          home-manager.users.deepwatrcreatur = {
            imports = [
              ./users/deepwatrcreatur
              ./users/deepwatrcreatur/hosts/macminim4.nix
              ./modules/home-manager
            ];
          };
          home-manager.extraSpecialArgs = homeManagerModuleArgs;

          users.users.deepwatrcreatur = {
            name = "deepwatrcreatur";
            home = "/Users/deepwatrcreatur";
            shell = pkgs.fish;
          };
        })
      ];
    };

    # --- NixOS Configurations ---
    nixosConfigurations = {
      ansible = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = systemSpecialArgs; # For NixOS system modules
        modules = [
          # ... other NixOS modules ...
          inputs.home-manager.nixosModules.home-manager
          # Anonymous module to configure HM user and pass correct extraSpecialArgs
          ({ config, lib, inputs, ... }: { # These are NixOS module args
            home-manager.users.ansible = {
              imports = [ ./modules ];
            };
            home-manager.extraSpecialArgs = homeManagerModuleArgs;
          })
        ];
      };

      homeserver = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = systemSpecialArgs; # For NixOS system modules
        modules = [
          inputs.sops-nix.nixosModules.sops
          inputs.home-manager.nixosModules.home-manager
          ./modules
          ./hosts/nixos
          (importAllModulesInDir ./hosts/homeserver/modules) 
        ];
      };
    };
  };
}
