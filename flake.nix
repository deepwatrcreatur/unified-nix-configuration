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
    pkgsForSystem = system: import nixpkgs {
      inherit system;
      config.allowUnfree = true; 
    };
  in
  {
    # Define nix-darwin configurations directly
    darwinConfigurations.macminim4 = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = {
        # Pass inputs or other variables as specialArgs if needed
        inherit inputs;
      };
      modules = [
        ./hosts/macminim4/default.nix
        ./hosts/common-darwin.nix
        # Import Home Manager as a nix-darwin module
        home-manager.darwinModules.home-manager
        {
          # Configure Home Manager for the deepwatrcreatur user on macminim4
          home-manager.users.deepwatrcreatur = {
            imports = [
              ./users/deepwatrcreatur/common.nix
              ./users/deepwatrcreatur/hosts/macminim4.nix
              ./modules/home-manager/common-home.nix
            ];
            home.stateVersion = "24.11";
            programs.home-manager.enable = true;
          };
        }
        # Make sure the system user's shell is set correctly here
        {
          users.users.deepwatrcreatur = {
            name = "deepwatrcreatur";
            # uid = 1000; # Optional: specify UID
            shell = pkgsForSystem "aarch64-darwin".fish; # Set login shell using pkgs for this system
          };
        }
      ];
    };

    # Define NixOS configurations directly
    nixosConfigurations.ansible = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/nixos-lxc/ansible/default.nix
        ./hosts/common-nixos.nix
        sops-nix.nixosModules.sops
        # Import Home Manager as a NixOS module
        home-manager.nixosModules.home-manager
        {
          # Configure Home Manager for the ansible user on ansible
          home-manager.users.ansible = {
            imports = [
              ./users/ansible/common.nix 
              # ./users/ansible/hosts/ansible.nix 
              modules/home-manager/common-home.nix 
            ];
            home.stateVersion = "24.11";
            programs.home-manager.enable = true;
          };
          # home-manager.useGlobalPkgs = true; # or false depending on setup
          # home-manager.useUserPackages = true;
        }
      ];
    };

    nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/homeserver/default.nix
        ./hosts/common-nixos.nix
        sops-nix.nixosModules.sops
        # Import Home Manager as a NixOS module
        home-manager.nixosModules.home-manager
        {
          # Configure Home Manager for deepwatrcreatur on homeserver
          home-manager.users.deepwatrcreatur = {
            imports = [
              ./users/deepwatrcreatur/common.nix
              ./users/deepwatrcreatur/hosts/homeserver.nix
              ./modules/home-manager/common-home.nix
            ];
            home.stateVersion = "24.11";
            programs.home-manager.enable = true;
          };
          # Configure Home Manager for root on homeserver (less common, but possible)
          home-manager.users.root = {
            imports = [
              ./users/root/common.nix
              ./users/root/hosts/homeserver.nix
              # modules/home-manager/common-home.nix # Root probably doesn't need this
            ];
             home.stateVersion = "24.11";
             programs.home-manager.enable = true;
          };
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
      ];
    };
  };
}
