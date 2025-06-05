# flake.nix
{
  description = "Multi-system Nix configurations (NixOS, nix-darwin, Home Manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    helix.url = "github:helix-editor/helix/2d14294b874207258057992f78010f80f03231a2";
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

    # Helper to import all .nix files from a directory as module paths
    importAllModulesInDir = dir:
      let
        items = builtins.readDir dir;
        # Use nixpkgsLib here
        isNixFile = name: type: type == "regular" && nixpkgsLib.hasSuffix ".nix" name;
        nixFileNames = nixpkgsLib.attrNames (nixpkgsLib.filterAttrs isNixFile items);
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
      specialArgs = systemSpecialArgs;
      modules = [
        {
          nixpkgs.overlays = commonOverlays;
          nixpkgs.config = commonNixpkgsConfig;
        }
        ./modules
        ./hosts/macminim4
        inputs.home-manager.darwinModules.home-manager
        ({ pkgs, config, lib, inputs, ... }: { # These are Darwin module args
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
        specialArgs = systemSpecialArgs;
        modules = [
          # You might want commonNixpkgsConfig and commonOverlays here too
          {
            nixpkgs.overlays = commonOverlays;
            nixpkgs.config = commonNixpkgsConfig;
          }
          # ./modules/nix-settings.nix 
          # ./hosts/nixos-lxc/ansible  
          # ./hosts/nixos
          inputs.sops-nix.nixosModules.sops
          inputs.home-manager.nixosModules.home-manager
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
        specialArgs = systemSpecialArgs;
        modules = [
          {
            nixpkgs.overlays = commonOverlays;
            nixpkgs.config = commonNixpkgsConfig;
          }
          inputs.sops-nix.nixosModules.sops
          inputs.home-manager.nixosModules.home-manager
          ./modules
          ./hosts/nixos
        ]
        ++(importAllModulesInDir ./hosts/homeserver/modules)
        # Optional local secrets from original flake
        ++ (if builtins.pathExists /etc/nixos/local-secrets.nix
            then [ /etc/nixos/local-secrets.nix ]
          else []);
      };
    };
  };
}
