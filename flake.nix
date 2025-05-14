{
  description = "Multi-system Nix configurations (NixOS, nix-darwin, Home Manager)";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts/c621e8422220273271f52058f618c94e405bb0f5";
    nixpkgs.url = "github:NixOS/nixpkgs/24.11";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Define supported systems for perSystem outputs
      systems = [ "aarch64-darwin" "x86_64-linux" ];

      flake = {
        # nix-darwin configuration for macminim4
        darwinConfigurations.macminim4 = inputs.nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { };
          modules = [
            ./hosts/macminim4/default.nix
            ./hosts/common-darwin.nix
            inputs.home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = false;
                extraSpecialArgs = {  };
                users.deepwatrcreatur = {
                  imports = [
                    ./users/deepwatrcreatur/common.nix
                    ./users/deepwatrcreatur/hosts/macminim4.nix
                  ];
                };
              };
            }
          ];
        };

       nixosConfigurations.ansible-lxc = inputs.nixpkgs.lib.nixosSystem {
         system = "x86_64-linux";
         specialArgs = { };
         modules = [
           ./hosts/nixos-lxc/ansible/default.nix
           ./hosts/common-nixos.nix
           inputs.sops-nix.nixosModules.sops
           inputs.home-manager.nixosModules.home-manager
           {
             home-manager = {
               useGlobalPkgs = true;
               useUserPackages = true;
               extraSpecialArgs = {  };
               users.ansible = {
                 imports = [
                   # user-specific modules
                 ];
                };
              };
            }
          ];
        };

        # NixOS configuration for homeserver
        nixosConfigurations.homeserver = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {  };
          modules = [
            ./hosts/homeserver/default.nix
            ./hosts/common-nixos.nix
            inputs.sops-nix.nixosModules.sops
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {  };
                users.deepwatrcreatur = {
                  imports = [
                    ./users/deepwatrcreatur/common.nix
                    ./users/deepwatrcreatur/hosts/homeserver.nix
                  ];
                };
                users.root = {
                  imports = [
                    ./users/root/common.nix
                    ./users/root/hosts/homeserver.nix
                  ];
                };
              };
            }
          ];
        };
      };

      # Per-system outputs (e.g., for home-manager standalone configs)
      perSystem = { config, pkgs, ... }:
        if pkgs.stdenv.isLinux then {
          homeConfigurations."deepwatrcreatur@pve-strix" = inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./users/deepwatrcreatur/common.nix
              #./users/deepwatrcreatur/hosts/pve-strix.nix
            ];
          };
        } else {};
  };
}
