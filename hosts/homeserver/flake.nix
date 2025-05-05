{
  description = "NixOS configuration for homeserver with Home Assistant module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    sops-nix.url = "github:Mic92/sops-nix";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = { self, nixpkgs, sops-nix, home-manager, ... }:
    let
      lib = nixpkgs.lib;
      # Helper function to import all .nix files from a directory
      importModules = path:
        let
          dirContents = builtins.readDir path;
          nixFiles = lib.filterAttrs (name: type:
            type == "regular" && lib.strings.hasSuffix ".nix" name
          ) dirContents;
        in
        lib.mapAttrsToList (name: _: path + "/${name}") nixFiles;
    in {
      nixosConfigurations.homeserver = lib.nixosSystem {
        system = "x86_64-linux";
        modules =
          [
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
          ]
          ../../modules/lxc-nixos-sh-wrapper.nix
          ++ (importModules ./modules)
          ++ [
            ({ config, pkgs, lib, ... }: {
              # === SOPS Configuration ===
              sops.secrets.REOLINK_CAMERA_PASSWORD = {
                sopsFile = "/etc/nixos/secrets/reolink-secrets.yaml";
                owner = "hass";
                group = "hass";
                mode = "0440";
              };
              sops.validateSopsFiles = false;
              sops.age.keyFile = "/etc/nixos/secrets/age-key.txt";
              users.users.hass.extraGroups = [ "keys" ];
              systemd.services."home-assistant".serviceConfig = {
                LoadCredential = lib.mkForce null;
                EnvironmentFile = config.sops.secrets.REOLINK_CAMERA_PASSWORD.path;
              };

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.deepwatrcreatur = import ./users/deepwatrcreatur.nix;
                users.root = import ./users/root.nix;
              };
              systemd.services."home-assistant".wants = [ "sops-nix.service" ];
              systemd.services."home-assistant".after = [ "sops-nix.service" ];
            })
            # Import the Home Assistant config from the separate file
            (import ./modules/home-assistant.nix)
          ];
      };
    };
}
