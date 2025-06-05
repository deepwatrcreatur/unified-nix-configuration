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

    # Helix flake input
    helix.url = "github:helix-editor/helix";
    helix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ ... }:
  let
    # Standard library
    lib = inputs.nixpkgs.lib;

    commonNixpkgsConfig = {
      allowUnfree = true;
    };

    commonOverlays = [
    ];

    # Common specialArgs for NixOS, Darwin, and Home Manager systems
    # Ensures modules can access flake inputs.
    commonSpecialArgs = { inherit inputs lib; }; # Pass top-level lib if needed by modules

    # Helper to import all .nix files from a directory as module paths.
    # This replaces a likely flakeLib.importModules helper.
    importAllModulesInDir = dir:
      let
        items = builtins.readDir dir;
        # Filter for regular files ending in .nix
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
        extraSpecialArgs = commonSpecialArgs;
        modules = [
          ./users/root/hosts/proxmox
          ./modules/home-manager 
        ];
      };
    };

    darwinConfigurations.macminim4 = inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = commonSpecialArgs;
      modules = [
        {
          nixpkgs.overlays = commonOverlays;
          nixpkgs.config = commonNixpkgsConfig;
        }

        ./modules
        ./hosts/macminim4

        inputs.home-manager.darwinModules.home-manager
        ({ pkgs, ... }: {
          home-manager.users.deepwatrcreatur = {
            imports = [
              ./users/deepwatrcreatur
              ./users/deepwatrcreatur/hosts/macminim4.nix
              ./modules/home-manager
            ];
          };
          users.users.deepwatrcreatur = {
            name = "deepwatrcreatur";
            home = "/Users/deepwatrcreatur";
            shell = pkgs.fish;
          };
        })
      ];
    };

    nixosConfigurations = {
      ansible = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = commonSpecialArgs;
        modules = [
          {
            nixpkgs.overlays = commonOverlays;
            nixpkgs.config = commonNixpkgsConfig;
          }

          ./modules/nix-settings.nix
          ./hosts/nixos-lxc/ansible
          ./hosts/nixos

          inputs.sops-nix.nixosModules.sops
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager.users.ansible = {
              imports = [
                ./modules
              ];
            };
          }
        ];
      };

      homeserver = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = commonSpecialArgs;
        modules = [
          {
            nixpkgs.overlays = commonOverlays;
            nixpkgs.config = commonNixpkgsConfig; # Added for consistency
          }
          inputs.sops-nix.nixosModules.sops
          inputs.home-manager.nixosModules.home-manager
          ./modules 
          ./hosts/nixos 
        ]
        ++ (importAllModulesInDir ./hosts/homeserver/modules) 
        ++ (if builtins.pathExists /etc/nixos/local-secrets.nix
          then [ /etc/nixos/local-secrets.nix ]
          else []);
      };
    };
  };
}
