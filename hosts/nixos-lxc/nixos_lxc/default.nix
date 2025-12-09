{
  config,
  lib,
  inputs,
  ...
}:
let
  nixpkgsLib = inputs.nixpkgs.lib;
  importAllModulesInDir =
    dir:
    let
      items = builtins.readDir dir;
      isNixFile = name: type: type == "regular" && nixpkgsLib.hasSuffix ".nix" name;
      nixFileNames = nixpkgsLib.attrNames (nixpkgsLib.filterAttrs isNixFile items);
    in
    map (fileName: dir + "/${fileName}") nixFileNames;
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    inputs.home-manager.nixosModules.home-manager
    (./. + "/../../../../modules")
    (./. + "/../../../hosts/nixos")
  ]
  ++ (importAllModulesInDir (./. + "/../../../hosts/nixos_lxc/modules"));

  nixpkgs = {
    overlays = [ ];
    config = {
      allowUnfree = true;
    };
  };
}
