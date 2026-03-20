{
  commonNixpkgsConfig,
  commonOverlays,
  helpers,
  homeManagerModuleArgs,
  importAllModulesInDir,
  inputs,
  nixpkgsLib,
  systemSpecialArgs,
  ...
}:
let
  framework = import ../experiments/den-lxc/framework.nix {
    inherit helpers nixpkgsLib;
  };

  inventory = import ../experiments/den-lxc/inventory;

  nixosOutputs = nixpkgsLib.mapAttrsToList (
    _: host: framework.mkNixosOutput (host // { outputName = "${host.name}-den"; })
  ) inventory.hosts;

  homeOutputs = nixpkgsLib.mapAttrsToList (
    _: home: framework.mkHomeOutput (home // { outputName = "${home.name}-den"; })
  ) inventory.homes;

  darwinOutputs = nixpkgsLib.mapAttrsToList (
    _: host: framework.mkDarwinOutput (host // { outputName = "${host.name}-den"; })
  ) inventory.darwin;

  bootstrapOutputs =
    let
      legacy = import ../outputs/nixos-lxc.nix {
        inherit
          helpers
          importAllModulesInDir
          inputs
          nixpkgsLib
          systemSpecialArgs
          homeManagerModuleArgs
          commonOverlays
          commonNixpkgsConfig
          ;
      };
    in
    {
      nixosConfigurations = nixpkgsLib.mapAttrs' (
        name: value: nixpkgsLib.nameValuePair "${name}-den" value
      ) legacy.nixosConfigurations;
    };
in
helpers.mergeOutputs (nixosOutputs ++ homeOutputs ++ darwinOutputs ++ [ bootstrapOutputs ])
