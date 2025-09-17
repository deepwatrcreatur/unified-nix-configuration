# flake.nix
{
  description = "Multi-system Nix configurations (NixOS, nix-darwin, Home Manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    nix-darwin.url = "github:LnL7/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    determinate.inputs.nixpkgs.follows = "nixpkgs";

    mac-app-util.url = "github:hraban/mac-app-util";

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    tap-romkatv-powerlevel10k = {
      url = "github:romkatv/powerlevel10k";
      flake = false;
    };

    tap-gabe565 = {
      url = "github:gabe565/homebrew-tap";
      flake = false;
    };

    tap-sst = {
      url = "github:sst/homebrew-tap";
      flake = false;
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    omarchy-nix = {
      url = "github:henrysipp/omarchy-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

  };

  outputs = inputs@{ ... }:
  let
    # Standard library from nixpkgs - this is the "pure" lib
    nixpkgsLib = inputs.nixpkgs.lib;

    commonNixpkgsConfig = {
      allowUnfree = true;
    };
    commonOverlays = [];

    # SpecialArgs for NixOS and Darwin SYSTEM modules.
    # These modules can safely receive the pure nixpkgsLib.
    systemSpecialArgs = { inherit inputs; lib = nixpkgsLib; };

    # SpecialArgs specifically for HOME MANAGER modules.
    # We only pass 'inputs'. Home Manager will provide its own 'lib' and 'config.lib'.
    homeManagerModuleArgs = { inherit inputs; inherit (inputs) mac-app-util; };

    # Helper to import all .nix files from a directory as module paths
    importAllModulesInDir = dir:
      let
        items = builtins.readDir dir;
        isNixFile = name: type: type == "regular" && nixpkgsLib.hasSuffix ".nix" name;
        nixFileNames = nixpkgsLib.attrNames (nixpkgsLib.filterAttrs isNixFile items);
      in
        map (fileName: dir + "/${fileName}") nixFileNames;

    # Helper functions to reduce boilerplate in individual host files
    helpers = {
      # Standard NixOS system builder
      mkNixosSystem = { system ? "x86_64-linux", hostPath, modules ? [], extraModules ? [] }:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = systemSpecialArgs;
          modules = [
            {
              nixpkgs.overlays = commonOverlays;
              nixpkgs.config = commonNixpkgsConfig;
            }
            inputs.sops-nix.nixosModules.sops
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = homeManagerModuleArgs;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.sharedModules = [
                inputs.sops-nix.homeManagerModules.sops
              ];
            }
            inputs.determinate.nixosModules.default
            ./modules
            hostPath
          ] ++ modules ++ extraModules;
        };

      # Standard Darwin system builder
      mkDarwinSystem = { system ? "aarch64-darwin", hostPath, username, modules ? [] }:
        let
          # Extract just the hostname from the path for user config
          hostName = builtins.baseNameOf (toString hostPath);
        in
        inputs.nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = systemSpecialArgs // {
            inherit (inputs) nix-homebrew;
          };
          modules = [
            {
              nixpkgs.overlays = commonOverlays;
              nixpkgs.config = commonNixpkgsConfig;
            }
            ./modules
            hostPath
            inputs.home-manager.darwinModules.home-manager
            ({ pkgs, ... }: {
              home-manager.users.${username} = {
                imports = [
                  ./users/${username}
                  ./users/${username}/hosts/${hostName}
                  ./modules/home-manager
                ];
              };
              home-manager.extraSpecialArgs = homeManagerModuleArgs;

              users.users.${username} = {
                name = username;
                home = "/Users/${username}";
                shell = pkgs.fish;
              };
            })
          ] ++ modules;
        };

      mkOmarchySystem = { system ? "x86_64-linux", hostPath, modules ? [], extraModules ? [] }:
        inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = systemSpecialArgs;
          modules = [
            {
              nixpkgs.overlays = commonOverlays;
              nixpkgs.config = commonNixpkgsConfig;
            }
            inputs.sops-nix.nixosModules.sops
            inputs.home-manager.nixosModules.home-manager
            inputs.determinate.nixosModules.default
            inputs.omarchy-nix.nixosModules.default
            {
              home-manager.extraSpecialArgs = homeManagerModuleArgs;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
            ./modules
            hostPath
          ] ++ modules ++ extraModules;
        };


      # Standard Home Manager configuration builder
      mkHomeConfig = { system ? "x86_64-linux", userPath, modules ? [] }:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import inputs.nixpkgs {
            inherit system;
            config = commonNixpkgsConfig;
            overlays = commonOverlays;
          };
          extraSpecialArgs = homeManagerModuleArgs;
          modules = [
            userPath
            ./modules/home-manager
          ] ++ modules;
        };
    };

    # Helper to load and merge all output configurations
    loadOutputs = outputsDir:
      let
        outputFiles = importAllModulesInDir outputsDir;
        # Create a context object that output files can use
        outputContext = {
          inherit inputs nixpkgsLib commonNixpkgsConfig commonOverlays
                  systemSpecialArgs homeManagerModuleArgs importAllModulesInDir helpers;
        };
      in
        nixpkgsLib.foldl' (acc: file:
          nixpkgsLib.recursiveUpdate acc (import file outputContext)
        ) {} outputFiles;

  in
    loadOutputs ./outputs;
}
