{
  inventoryOutputs,
  ...
}:
let
  inventory = import ../inventory/legacy;
in
inventoryOutputs.mkInventoryOutputs {
  inherit inventory;
}
