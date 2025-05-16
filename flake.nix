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
    # Helper to import modules from a directory (optional, can list manually)
    # Keep the logic from your homeserver flake's `importModules` helper
    lib = nixpkgs.lib; # Get lib here
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
    # nix-darwin configuration for macminim4
    darwinConfigurations.macminim4 = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/macminim4/default.nix
        ./hosts/common-darwin.nix
        home-manager.darwinModules.home-manager # Import HM module for darwin
        {
          home-manager.users.deepwatrcreatur = {
            imports = [
              ./users/deepwatrcreatur/common.nix
              ./users/deepwatrcreatur/hosts/macminim4.nix
              ./modules/home-manager/common-home.nix 
            ];
            # home.stateVersion = "24.11"; 
          };
          # Use global pkgs and user packages configuration as needed
          # home-manager.useGlobalPkgs = true;
          # home-manager.useUserPackages = false;
        }
        # Inline module to set the system user's shell at the nix-darwin level
        ({ pkgs, ... }: { # Accepts pkgs
          users.users.deepwatrcreatur = {
            name = "deepwatrcreatur";
            # uid = 1000; # Optional: specify UID for consistency
            # ... other system user settings like groups, isNormalUser, home
            isNormalUser = true; # Ensure this is set here or in common-darwin/macminim4/default.nix
            home = "/Users/deepwatrcreatur"; # Ensure this is set correctly
            shell = pkgs.fish; # Use pkgs provided to this module
          };
        })
      ];
    };

    # NixOS configuration for ansible
    nixosConfigurations.ansible = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/nixos-lxc/ansible/default.nix
        ./hosts/common-nixos.nix
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager # Import HM module for nixos
        {
          # Configure Home Manager for the ansible user on ansible
          home-manager.users.ansible = {
            imports = [
              # ./users/ansible/common.nix # Example
              # ./users/ansible/hosts/ansible.nix # Example
              # ./modules/home-manager/common-home.nix # Example if ansible user uses fish/starship
            ];
            # home.stateVersion = "...";
            # programs.home-manager.enable = true; # Not needed here
          };
           # Use global pkgs and user packages configuration as needed
           # home-manager.useGlobalPkgs = true;
           # home-manager.useUserPackages = true;
        }
        # Ensure the system user is defined at the system level if not already
        # ({ pkgs, ... }: { users.users.ansible.isNormalUser = true; ... })
      ];
    };

    nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; }; 
      modules =
        [
          sops-nix.nixosModules.sops        
          home-manager.nixosModules.home-manager 
          ./hosts/common-nixos.nix          
          #./hosts/homeserver/default.nix    
        ]
        ++ (importModules ./hosts/homeserver/modules) 
        ++ [
          ./hosts/homeserver/homeserver-homeassistant.nix 

          ({ config, pkgs, lib, ... }: { 
            sops.secrets.REOLINK_CAMERA_PASSWORD = {
              sopsFile = "./secrets/reolink-secrets.yaml";
              owner = "hass";
              group = "hass";
              mode = "0440";
            };
            sops.validateSopsFiles = false; # Consider enabling this once comfortable
            sops.age.keyFile = "./secrets/age-key.txt";
            users.users.hass.extraGroups = [ "keys" ];

            sops.secrets.influxdb_password = {
              sopsFile = builtins.path { path = ./secrets/influxdb-secrets.yaml; }; 
              owner = "influxdb2"; 
            };


            systemd.services."home-assistant".serviceConfig = {
              # Note: EnvironmentFile loading a sops secret path might be tricky
              # depending on sops-nix version and service startup order.
              # LoadCredential is a standard way but seems mkForce null is used here?
              # Re-evaluate how this secret is passed if issues arise.
              LoadCredential = lib.mkForce null; 
              EnvironmentFile = config.sops.secrets.REOLINK_CAMERA_PASSWORD.path;
            };

            # Home Manager configuration for homeserver users
            home-manager = {
              useGlobalPkgs = true; # As per original config
              useUserPackages = true; # As per original config
              users.deepwatrcreatur = { # Configure deepwatrcreatur user on homeserver
                 imports = [
                    ./users/deepwatrcreatur/common.nix # Import common HM settings
                    ./users/deepwatrcreatur/hosts/homeserver.nix # Import homeserver-specific user settings (merge ../homeserver/users/deepwatrcreatur.nix here)
                    ./modules/home-manager/common-home.nix # Make sure this is imported if the user needs fish/starship etc.
                 ];
                 # home.stateVersion = "...";
              };
              users.root = { 
                 imports = [
                    ./users/root/common.nix 
                    #./users/root/hosts/homeserver.nix 
                 ];
                 # home.stateVersion = "..."; 
              };
            };

            systemd.services."home-assistant".wants = [ "sops-nix.service" ];
            systemd.services."home-assistant".after = [ "sops-nix.service" ];

          }) 
        ]; 
    };
  };
}
