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

  outputs = inputs@{ nixpkgs, home-manager, nix-darwin, sops-nix, ... }:
  let
    # Helper to import modules from a directory
    lib = nixpkgs.lib;
    importModules = path:
      let
        dirContents = builtins.readDir path;
        nixFiles = lib.filterAttrs (name: type:
          type == "regular" && lib.strings.hasSuffix ".nix" name
        ) dirContents;
      in
      lib.mapAttrsToList (name: _: path + "/${name}") nixFiles;

  in
  {
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations = {
        # Add this block for Proxmox root user
        proxmox-root = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./users/root/hosts/proxmox.nix
            ./modules/home-manager
          ];
        };
      };
    };
      
    # nix-darwin configuration for macminim4
    darwinConfigurations.macminim4 = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = { inherit inputs; };
      modules = [
        ./modules
        ./hosts/macminim4
        home-manager.darwinModules.home-manager
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

    # NixOS configuration for ansible
    nixosConfigurations.ansible = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./modules/nix-settings.nix
        ./hosts/nixos-lxc/ansible
        ./hosts/nixos
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        {
          home-manager.users.ansible = {
            imports = [
              ./modules
              # ./users/ansible/hosts/ansible.nix
            ];
          };
        }
      ];
    };

    nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules =
        [
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          ./modules
          ./hosts/nixos
        ]
        ++ (importModules ./hosts/homeserver/modules)
        ++ [
          ({ config, pkgs, lib, ... }: {
            sops.age.keyFile = "/etc/nixos/secrets/age-key.txt";
            sops.validateSopsFiles = false;

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.deepwatrcreatur = {
                imports = [
                  ./users/deepwatrcreatur
                  ./users/deepwatrcreatur/hosts/homeserver.nix
                  ./modules/home-manager
                ];
              };
              users.root = {
                imports = [
                  ./users/root
                  ./modules/home-manager
                ];
              };
            };
          })
        ];
    };
  };
}
