{
  helpers,
  nixpkgsLib,
}:
let
  stripInventoryMetadata = item: builtins.removeAttrs item [ "kind" "mode" "aspectsList" "archived" ];
  mapInventory =
    inventory: transform: builder:
    # Inventory entries may remain tracked for history even after retirement.
    # Archived entries are intentionally excluded from generated outputs.
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
