{
  helpers,
  inventoryOutputs,
  nixpkgsLib,
  ...
}:
let
  framework = import ../den/framework.nix {
    inherit helpers nixpkgsLib;
  };

  inventory = import ../den/inventory;
in
inventoryOutputs.mkInventoryOutputs {
  inherit inventory;
}
