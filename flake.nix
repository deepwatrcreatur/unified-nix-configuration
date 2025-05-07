{
  description = "Multi-system Nix configurations (NixOS, nix-darwin, Home Manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # Or your preferred channel

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = { # If you use sops-nix
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # agenix = { # If you use agenix
    #   url = "github:ryantm/agenix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, sops-nix, ... }@inputs:
    let
      lib = nixpkgs.lib;

      # Common arguments to pass to NixOS, darwin, and Home Manager modules
      commonSpecialArgs = {
        inherit inputs lib;
        # You can add other shared values here, e.g., username = "deepwatrcreatur";
      };

      # Helper to build Home Manager configurations for different systems
      mkHomeManagerConfig = system: user: hostSpecificUserModule: [
        # User-specific settings for this host
        hostSpecificUserModule
        # Common settings for this user across all systems
        ./users/${user}/common.nix
        # Common settings for all standalone Home Manager configurations (optional)
        # ./hosts/common-home-manager.nix
        # Secrets module for Home Manager (if needed and sops-nix is used)
        # sops-nix.homeManagerModules.sops # If you manage user secrets this way
      ];

    in
    {
      # --- NixOS Configurations ---
      nixosConfigurations = {
        homeserver = lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = commonSpecialArgs;
          modules = [
            ./hosts/homeserver/default.nix
            ./hosts/common-nixos.nix # Common settings for all NixOS hosts
            sops-nix.nixosModules.sops # If homeserver uses sops-nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = commonSpecialArgs;
                users.deepwatrcreatur = import ./users/deepwatrcreatur/homeserver.nix;
                users.root = import ./users/root/homeserver.nix; # If managing root's HM
              };
            }
            # Import your custom NixOS modules from ./modules/nixos/ if needed
            # e.g., ./modules/nixos/homeAssistant.nix
          ];
        };

        inference1 = lib.nixosSystem {
          system = "x86_64-linux"; # Or aarch64-linux if applicable
          specialArgs = commonSpecialArgs;
          modules = [
            ./hosts/inference1/default.nix
            ./hosts/common-nixos.nix
            # sops-nix.nixosModules.sops # If inference1 uses sops-nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = commonSpecialArgs;
                users.deepwatrcreatur = import ./users/deepwatrcreatur/inference1.nix;
              };
            }
          ];
        };
        # Add other NixOS VMs/containers here
      };

      # --- nix-darwin Configurations ---
      darwinConfigurations = {
        macminim4 = nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin"; # Or "x86_64-darwin"
          specialArgs = commonSpecialArgs;
          modules = [
            ./hosts/macminim4/default.nix
            ./hosts/common-darwin.nix # Optional: common settings for all darwin hosts
            # sops-nix.darwinModules.sops # If macminim4 uses sops-nix for system secrets
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true; # Or false, depending on preference
                useUserPackages = true;
                extraSpecialArgs = commonSpecialArgs;
                users.deepwatrcreatur = import ./users/deepwatrcreatur/macminim4.nix;
              };
            }
            # Import custom darwin modules from ./modules/darwin/ if needed
          ];
        };
      };

      # --- Standalone Home Manager Configurations ---
      homeConfigurations = {
        "deepwatrcreatur@pve-strix" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux; # System of pve-strix
          extraSpecialArgs = commonSpecialArgs;
          modules = mkHomeManagerConfig "x86_64-linux" "deepwatrcreatur" ./users/deepwatrcreatur/pve-strix.nix;
        };

        # If you wanted to manage deepwatrcreatur's HM on macminim4 this way too (alternative to integrating with darwinSystem)
        # "deepwatrcreatur@macminim4-standalone" = home-manager.lib.homeManagerConfiguration {
        #   pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        #   extraSpecialArgs = commonSpecialArgs;
        #   modules = mkHomeManagerConfig "aarch64-darwin" "deepwatrcreatur" ./users/deepwatrcreatur/macminim4.nix;
        # };
      };

      # You can also expose packages, devShells, overlays, etc.
      # Example:
      # packages.x86_64-linux.my-custom-package = pkgs.callPackage ./pkgs/my-custom-package {};
    };
}
