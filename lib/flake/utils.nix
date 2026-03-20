{
  nixpkgsLib,
}:
{
  importAllModulesInDir =
    dir:
    let
      items = builtins.readDir dir;
      isNixFile =
        name: type: type == "regular" && nixpkgsLib.hasSuffix ".nix" name && !nixpkgsLib.hasPrefix "_" name;
      nixFileNames = nixpkgsLib.attrNames (nixpkgsLib.filterAttrs isNixFile items);
    in
    map (fileName: dir + "/${fileName}") nixFileNames;

  autoImportCommon =
    {
      commonDir,
      lib,
      includeDirectories ? true,
      excludeFiles ? [ ],
    }:
    let
      items = builtins.readDir commonDir;
      isValidItem =
        name: type:
        (type == "regular" && nixpkgsLib.hasSuffix ".nix" name && !nixpkgsLib.elem name excludeFiles)
        || (includeDirectories && type == "directory");
      validItems = nixpkgsLib.filterAttrs isValidItem items;
    in
    lib.mapAttrsToList (name: _: commonDir + "/${name}") validItems;

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
}
