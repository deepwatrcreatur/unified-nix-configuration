{
  inputs,
  nixpkgsLib,
  repoRoot,
  shared,
}:
let
  inherit (shared)
    commonNixpkgsConfig
    commonOverlays
    systemSpecialArgs
    homeManagerModuleArgs
    ;

  commonSystemModules = [
    {
      nixpkgs.overlays = commonOverlays;
      nixpkgs.config = commonNixpkgsConfig;
    }
  ];

  nixosHomeManagerConfig =
    { hostName, isDesktop }:
    {
      home-manager.extraSpecialArgs = homeManagerModuleArgs // {
        inherit hostName isDesktop;
      };
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
    };

  omarchyHomeManagerConfig = {
    home-manager.extraSpecialArgs = homeManagerModuleArgs;
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
  };

  helpers = rec {
    mkNixosSystem =
      {
        system ? inputs.nixpkgs.system,
        hostPath,
        hostName ? builtins.baseNameOf (toString hostPath),
        modules ? [ ],
        extraModules ? [ ],
        isDesktop ? false,
        includeSnapd ? true,
      }:
      let
        baseModules = commonSystemModules ++ [
          inputs.agenix.nixosModules.default
          inputs.home-manager.nixosModules.home-manager
          (nixosHomeManagerConfig { inherit hostName isDesktop; })
          inputs.tesla-inference-flake.nixosModules.tesla-inference
          inputs.nix-linuxbrew.nixosModules.default
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
            (repoRoot + "/modules")
            hostPath
          ]
          ++ modules
          ++ extraModules;
      };

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
            (repoRoot + "/modules")
            hostPath
            inputs.home-manager.darwinModules.home-manager
            (
              { pkgs, ... }:
              {
                home-manager.users.${username} = {
                  imports = [
                    (repoRoot + "/users/${username}")
                    (repoRoot + "/users/${username}/hosts/${hostName}")
                    (repoRoot + "/modules/home-manager")
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
            (repoRoot + "/modules")
            hostPath
          ]
          ++ modules
          ++ extraModules;
      };

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
          (repoRoot + "/modules/home-manager")
        ] ++ modules;
      };

    mkHomeOutput =
      {
        outputName ? name,
        name,
        targetSystem ? inputs.nixpkgs.system,
        hostName ? name,
        userPath,
        modules ? [ ],
        isDesktop ? false,
        extraSpecialArgs ? { },
      }:
      nixpkgsLib.setAttrByPath [ "homeConfigurations" outputName ] (
        mkHomeConfig {
          inherit
            targetSystem
            hostName
            userPath
            modules
            isDesktop
            extraSpecialArgs
            ;
        }
      );

    mkNixosOutput =
      {
        outputName ? name,
        name,
        system ? inputs.nixpkgs.system,
        hostPath,
        hostName ? builtins.baseNameOf (toString hostPath),
        modules ? [ ],
        extraModules ? [ ],
        isDesktop ? false,
        includeSnapd ? true,
      }:
      nixpkgsLib.setAttrByPath [ "nixosConfigurations" outputName ] (
        mkNixosSystem {
          inherit
            system
            hostPath
            hostName
            modules
            extraModules
            isDesktop
            includeSnapd
            ;
        }
      );

    mkDarwinOutput =
      {
        outputName ? name,
        name,
        system ? inputs.nix-darwin.system,
        hostPath,
        username,
        modules ? [ ],
        isDesktop ? true,
      }:
      nixpkgsLib.setAttrByPath [ "darwinConfigurations" outputName ] (
        mkDarwinSystem {
          inherit
            system
            hostPath
            username
            modules
            isDesktop
            ;
        }
      );

    mergeOutputs =
      outputs: nixpkgsLib.foldl' (acc: out: nixpkgsLib.recursiveUpdate acc out) { } outputs;
  };
in
{
  inherit
    commonSystemModules
    nixosHomeManagerConfig
    omarchyHomeManagerConfig
    helpers
    ;
}
