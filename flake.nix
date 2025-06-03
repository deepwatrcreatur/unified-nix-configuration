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
  };

  outputs = inputs@{ ... }: # '@' captures all inputs into the 'inputs' attrset
  let
    # Import our custom library from flake-modules
    flakeLib = import ./flake-modules/lib.nix { inherit inputs; };

    # Convenience alias for nixpkgs.lib from our flakeLib
    lib = flakeLib.lib;

    # Common specialArgs for NixOS and Darwin systems
    # Ensures modules within those systems can access flake inputs and our flakeLib
    commonSpecialArgs = { inherit inputs flakeLib; };

  in
  {
    # --- Packages Output ---
    packages = import ./flake-modules/packages.nix {
      inherit inputs;
      lib = flakeLib.lib; # Pass the 'lib' attribute from flakeLib
      overlaysList = flakeLib.allOverlays; # Pass 'allOverlays' from flakeLib as 'overlaysList'
    };

    # --- Home Manager Configurations (Standalone) ---
    homeConfigurations = {
      proxmox-root = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config = inputs.nixpkgs.config;
          overlays = flakeLib.allOverlays; # Use shared overlays
        };
        extraSpecialArgs = commonSpecialArgs; # Pass inputs and flakeLib
        modules = [
          ./users/root/hosts/proxmox
          ./modules/home-manager # General home-manager modules
        ];
      };
    };

    # --- Darwin Configurations ---
    darwinConfigurations.macminim4 = inputs.nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = commonSpecialArgs; # Pass inputs and flakeLib
      modules = [
        { nixpkgs.overlays = flakeLib.allOverlays; }

        ./modules
        ./hosts/macminim4

        inputs.home-manager.darwinModules.home-manager
        ({ pkgs, ... }: { # pkgs here will have the overlays applied
          home-manager.users.deepwatrcreatur = {
            imports = [
              ./users/deepwatrcreatur 
              ./users/deepwatrcreatur/hosts/macminim4.nix
              ./modules/home-manager
            ];
          };
          # System-level user definition
          users.users.deepwatrcreatur = {
            name = "deepwatrcreatur";
            home = "/Users/deepwatrcreatur";
            shell = pkgs.fish; # pkgs.fish will come from the overlaid pkgs
          };
        })
      ];
    };

    nixosConfigurations = {
      ansible = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = commonSpecialArgs; # Pass inputs and flakeLib
        modules = [
          { nixpkgs.overlays = flakeLib.allOverlays; }

          ./modules/nix-settings.nix
          ./hosts/nixos-lxc/ansible
          ./hosts/nixos 

          inputs.sops-nix.nixosModules.sops
          inputs.home-manager.nixosModules.home-manager
          { # pkgs here will have the overlays applied
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
          { nixpkgs.overlays = flakeLib.allOverlays; }
          inputs.sops-nix.nixosModules.sops
          inputs.home-manager.nixosModules.home-manager
          ./modules # Common system modules
          ./hosts/nixos # Common NixOS modules
        ]
        # Use the importModules helper from flakeLib
        ++ (flakeLib.importModules ./hosts/homeserver/modules)
        ++ (if builtins.pathExists /etc/nixos/local-secrets.nix
          then [ /etc/nixos/local-secrets.nix ]
          else []);
      };
    };
  };
}
