{
  commonNixpkgsConfig,
  commonOverlays,
  helpers,
  homeManagerModuleArgs,
  importAllModulesInDir,
  inventoryOutputs,
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
inventoryOutputs.mkInventoryOutputs {
  inherit inventory;
  nixosTransform = host: host // { outputName = "${host.name}-den"; };
  homeTransform = home: home // { outputName = "${home.name}-den"; };
  darwinTransform = host: host // { outputName = "${host.name}-den"; };
  extraOutputs = [ bootstrapOutputs ];
}
