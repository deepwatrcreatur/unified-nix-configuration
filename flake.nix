# flake.nix
{
  description = "Multi-system Nix configurations (NixOS, nix-darwin, Home Manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    determinate.inputs.nixpkgs.follows = "nixpkgs";

    mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.inputs.flake-utils.follows = "flake-utils";

    flake-utils.url = "github:numtide/flake-utils";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixbit = {
      url = "github:pbek/nixbit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nix-snapd = {
      url = "github:nix-community/nix-snapd";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-whitesur-config = {
      url = "git+ssh://git@github.com/deepwatrcreatur/nix-whitesur-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-linuxbrew = {
      url = "git+ssh://git@github.com/deepwatrcreatur/nix-linuxbrew?ref=refs/tags/v1.0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tesla-inference-flake = {
      url = "git+ssh://git@github.com/deepwatrcreatur/tesla-inference-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fnox = {
      url = "git+ssh://git@github.com/deepwatrcreatur/fnox-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      flake = true;
    };

    zellij-vivid-rounded = {
      url = "git+ssh://git@github.com/deepwatrcreatur/nix-zellij-vivid-rounded";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gnome-cosmic-ui = {
      url = "git+ssh://git@github.com/deepwatrcreatur/nix-gnome-cosmic-ui";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    worktrunk = {
      url = "git+ssh://git@github.com/max-sixty/worktrunk";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    nix-attic-infra = {
      url = "git+ssh://git@github.com/deepwatrcreatur/nix-attic-infra?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    ssh-keys-manager = {
      url = "git+ssh://git@github.com/deepwatrcreatur/nix-ssh-keys-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-router-optimized = {
      url = "github:deepwatrcreatur/nix-router-optimized";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dmux-flake = {
      url = "github:deepwatrcreatur/nix-dmux"; # Your new dmux package flake
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-statusline-flake = {
      url = "github:deepwatrcreatur/nix-claude-statusline"; # Your new claude-statusline package flake
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agents-status-tray-home-manager = {
      url = "github:deepwatrcreatur/agents-status-tray-home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    cosmic-applet-proxmoxbar = {
      url = "github:deepwatrcreatur/cosmic-applet-proxmoxbar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cosmic-applet-agents-status = {
      url = "github:deepwatrcreatur/cosmic-applet-agents-status";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs:
    let
      # Standard library from nixpkgs - this is the "pure" lib
      nixpkgsLib = inputs.nixpkgs.lib;

      commonNixpkgsConfig = {
        allowUnfree = true;
      };

      commonOverlays = import ./overlays {
        inherit
          inputs
          commonNixpkgsConfig
          nixpkgsLib
          ;
      };

      # SpecialArgs for NixOS and Darwin SYSTEM modules.
      # These modules can safely receive the pure nixpkgsLib.
      systemSpecialArgs = {
        inherit inputs;
        lib = nixpkgsLib;
        myModules = import ./modules;
      };

      # SpecialArgs specifically for HOME MANAGER modules.
      # We only pass 'inputs'. Home Manager will provide its own 'lib' and 'config.lib'.
      homeManagerModuleArgs = {
        inherit inputs;
        inherit (inputs) mac-app-util;
      };

      # Helper to import all .nix files from a directory as module paths
      importAllModulesInDir =
        dir:
        let
          items = builtins.readDir dir;
          isNixFile =
            name: type: type == "regular" && nixpkgsLib.hasSuffix ".nix" name && !nixpkgsLib.hasPrefix "_" name;
          nixFileNames = nixpkgsLib.attrNames (nixpkgsLib.filterAttrs isNixFile items);
        in
        map (fileName: dir + "/${fileName}") nixFileNames;

      # Helper to auto-import all .nix files and directories from a common directory
      # Used by module default.nix files to automatically load all modules from a common subdirectory
      autoImportCommon =
        {
          commonDir,
          lib,
          includeDirectories ? true,
          excludeFiles ? [ ],
        }:
        let
          items = builtins.readDir commonDir;
          # Filter to include .nix files and optionally directories
          isValidItem =
            name: type:
            (type == "regular" && nixpkgsLib.hasSuffix ".nix" name && !nixpkgsLib.elem name excludeFiles)
            || (includeDirectories && type == "directory");
          validItems = nixpkgsLib.filterAttrs isValidItem items;
        in
        nixpkgsLib.mapAttrsToList (name: _: commonDir + "/${name}") validItems;

      # Helper to create platform-specific modules with base + platform-specific extensions
      # Usage: mkPlatformModule { base = "..."; darwin = "..."; nixos = "..."; }
      mkPlatformModule =
        pkgs:
        {
          base ? "",
          darwin ? "",
          nixos ? "",
        }:
        base
        + (
          if pkgs.stdenv.isDarwin then
            darwin
          else if pkgs.stdenv.isLinux then
            nixos
          else
            ""
        );

      # Common module configurations shared across all system builders
      commonSystemModules = [
        {
          nixpkgs.overlays = commonOverlays;
          nixpkgs.config = commonNixpkgsConfig;
        }
      ];

      # Home Manager configuration for NixOS systems (used by mkNixosSystem)
      nixosHomeManagerConfig =
        { hostName, isDesktop }:
        {
          home-manager.extraSpecialArgs = homeManagerModuleArgs // {
            inherit hostName isDesktop;
          };
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        };

      # Home Manager configuration for Omarchy systems (minimal variant)
      omarchyHomeManagerConfig = {
        home-manager.extraSpecialArgs = homeManagerModuleArgs;
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      };

      # Helper functions to reduce boilerplate in individual host files
      helpers = {
        # Standard NixOS system builder
        mkNixosSystem =
          {
            system ? inputs.nixpkgs.system,
            hostPath,
            modules ? [ ],
            extraModules ? [ ],
            isDesktop ? false,
            includeSnapd ? true,
          }:
          let
            hostName = builtins.baseNameOf (toString hostPath);
            baseModules = commonSystemModules ++ [
              inputs.agenix.nixosModules.default
              inputs.home-manager.nixosModules.home-manager
              (nixosHomeManagerConfig { inherit hostName isDesktop; })
              # inputs.determinate.nixosModules.default # TEMPORARILY DISABLED
              inputs.tesla-inference-flake.nixosModules.tesla-inference
            ];
            snapdModules = nixpkgsLib.optionals includeSnapd [
              inputs.nix-snapd.nixosModules.default
            ];
          in
          inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = systemSpecialArgs;
            modules =
              baseModules
              ++ snapdModules
              ++ [
                ./modules
                hostPath
              ]
              ++ modules
              ++ extraModules;
          };

        # Standard Darwin system builder
        mkDarwinSystem =
          {
            system ? inputs.nix-darwin.system,
            hostPath,
            username,
            modules ? [ ],
            isDesktop ? true,
          }:
          let
            hostName = builtins.baseNameOf (toString hostPath);
          in
          inputs.nix-darwin.lib.darwinSystem {
            inherit system;
            specialArgs = systemSpecialArgs // {
              inherit (inputs) nix-homebrew;
            };
            modules =
              commonSystemModules
              ++ [
                ./modules
                hostPath
                inputs.home-manager.darwinModules.home-manager
                (
                  { pkgs, ... }:
                  {
                    home-manager.users.${username} = {
                      imports = [
                        ./users/${username}
                        ./users/${username}/hosts/${hostName}
                        ./modules/home-manager
                      ];
                    };
                    home-manager.extraSpecialArgs = homeManagerModuleArgs // {
                      inherit hostName isDesktop;
                    };
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                  }
                )
                (
                  { pkgs, ... }:
                  {
                    users.users.${username} = {
                      name = username;
                      home = "/Users/${username}";
                      shell = pkgs.fish;
                    };
                  }
                )
              ]
              ++ modules;
          };

        mkOmarchySystem =
          {
            system ? inputs.nixpkgs.system,
            hostPath,
            modules ? [ ],
            extraModules ? [ ],
          }:
          let
            hostName = builtins.baseNameOf (toString hostPath);
          in
          inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = systemSpecialArgs;
            modules =
              commonSystemModules
              ++ [
                inputs.agenix.nixosModules.default
                inputs.home-manager.nixosModules.home-manager
                inputs.determinate.nixosModules.default
                omarchyHomeManagerConfig
                ./modules
                hostPath
              ]
              ++ modules
              ++ extraModules;
          };

        # Standard Home Manager configuration builder
        mkHomeConfig =
          {
            targetSystem ? inputs.nixpkgs.system,
            hostName ? "",
            userPath,
            modules ? [ ],
            isDesktop ? false,
            extraSpecialArgs ? { },
          }:
          inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = import inputs.nixpkgs {
              system = targetSystem;
              config = commonNixpkgsConfig;
              overlays = commonOverlays;
            };
            extraSpecialArgs =
              homeManagerModuleArgs
              // {
                inherit isDesktop hostName;
              }
              // extraSpecialArgs;
            modules = [
              userPath
              ./modules/home-manager
            ]
            ++ modules;
          };

        # Output builder for single NixOS configuration
        mkNixosOutput =
          {
            name,
            system ? inputs.nixpkgs.system,
            hostPath,
            modules ? [ ],
            extraModules ? [ ],
            isDesktop ? false,
            includeSnapd ? true,
          }:
          nixpkgsLib.setAttrByPath [ "nixosConfigurations" name ] (
            helpers.mkNixosSystem {
              inherit
                system
                hostPath
                modules
                extraModules
                isDesktop
                includeSnapd
                ;
            }
          );

        # Output builder for single Darwin configuration
        mkDarwinOutput =
          {
            name,
            system ? inputs.nix-darwin.system,
            hostPath,
            username,
            modules ? [ ],
            isDesktop ? true,
          }:
          nixpkgsLib.setAttrByPath [ "darwinConfigurations" name ] (
            helpers.mkDarwinSystem {
              inherit
                system
                hostPath
                username
                modules
                isDesktop
                ;
            }
          );

        # Merge multiple output configurations (used for files with multiple hosts)
        # Use recursiveUpdate to properly merge nested nixosConfigurations
        mergeOutputs =
          outputs: nixpkgsLib.foldl' (acc: out: nixpkgsLib.recursiveUpdate acc out) { } outputs;
      };

      # Helper to load and merge all output configurations
      loadOutputs =
        outputsDir:
        let
          outputFiles = importAllModulesInDir outputsDir;
          # Create a context object that output files can use
          outputContext = {
            inherit
              inputs
              nixpkgsLib
              commonNixpkgsConfig
              commonOverlays
              systemSpecialArgs
              homeManagerModuleArgs
              importAllModulesInDir
              helpers
              ;
          };
        in
        nixpkgsLib.foldl' (
          acc: file: nixpkgsLib.recursiveUpdate acc (import file outputContext)
        ) { } outputFiles;

    in
    (loadOutputs ./outputs)
    // {
      hm-opts = helpers.mkHomeConfig {
        targetSystem = "x86_64-linux";
        hostName = "";
        userPath = ./modules/home-manager/non-nixos.nix;
      };
    };
}
