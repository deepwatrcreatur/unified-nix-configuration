{
  helpers,
  nixpkgsLib,
}:
let
  stripInventoryMetadata = item: builtins.removeAttrs item [ "kind" "mode" "aspectsList" "archived" ];
  mapInventory =
    inventory: transform: builder:
    nixpkgsLib.mapAttrsToList (_: item: builder (stripInventoryMetadata (transform item))) (
      nixpkgsLib.filterAttrs (_: item: !(item.archived or false)) inventory
    );
in
{
  mkInventoryOutputs =
    {
      inventory,
      nixosTransform ? (host: host),
      homeTransform ? (home: home),
      darwinTransform ? (host: host),
      extraOutputs ? [ ],
    }:
    helpers.mergeOutputs (
      (mapInventory inventory.hosts nixosTransform helpers.mkNixosOutput)
      ++ (mapInventory inventory.homes homeTransform helpers.mkHomeOutput)
      ++ (mapInventory inventory.darwin darwinTransform helpers.mkDarwinOutput)
      ++ extraOutputs
    );
}
