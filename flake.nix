# flake.nix (snippet)
{
  description = "Multi-system Nix configurations (NixOS, nix-darwin, Home Manager)";

  inputs = {
    # ... (your existing inputs) ...
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, sops-nix, ... }@inputs:
    let
      lib = nixpkgs.lib;

      # Common arguments to pass to NixOS, darwin, and Home Manager modules
      commonSpecialArgs = {
        inherit inputs lib;
        # You can add other shared values here, e.g., username = "deepwatrcreatur";
      };

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
                users.deepwatrcreatur = {
                  imports = [
                    ./users/deepwatrcreatur/common.nix # Direct import of common.nix
                    ./users/deepwatrcreatur/hosts/homeserver.nix # Host-specific overrides
                  ];
                };
                 users.root = { # If managing root's HM
                   imports = [
                     ./users/root/common.nix
                     ./users/root/hosts/homeserver.nix # Assuming root also has host-specific
                   ];
                 };
              };
            }
          ];
        };

        inference1 = lib.nixosSystem {
          system = "x86_64-linux"; # Or aarch64-linux if applicable
          specialArgs = commonSpecialArgs;
          modules = [
            ./hosts/inference1/default.nix
            ./hosts/common-nixos.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = commonSpecialArgs;
                users.deepwatrcreatur = {
                  imports = [
                    ./users/deepwatrcreatur/common.nix # Direct import of common.nix
                    ./users/deepwatrcreatur/hosts/inference1.nix # Host-specific overrides
                  ];
                };
              };
            }
          ];
        };
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
                users.deepwatrcreatur = {
                  imports = [
            #        #./users/deepwatrcreatur/common.nix # Direct import of common.nix
            #        #./users/deepwatrcreatur/hosts/macminim4.nix # Host-specific overrides
                  ];
                };
              };
            }
          ];
        };
      };

      # --- Standalone Home Manager Configurations ---
      homeConfigurations = {
        "deepwatrcreatur@pve-strix" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux; # System of pve-strix
          extraSpecialArgs = commonSpecialArgs;
          modules = [
            ./users/deepwatrcreatur/common.nix # Direct import of common.nix
            ./users/deepwatrcreatur/hosts/pve-strix.nix # Host-specific overrides
          ];
        };
      };
    };
}
