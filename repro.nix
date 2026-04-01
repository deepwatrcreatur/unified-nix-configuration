let
  pkgs = import <nixpkgs> {};
  denInventory = import ./den/inventory;
  inventoryHosts = denInventory.hosts;
  libHosts = (import ./lib/hosts.nix).hosts;
  
  inventoryHostNames = builtins.attrNames inventoryHosts;
  
  hostNamesExpectedInLib =
    builtins.filter
      (name:
        !(builtins.elem name [
          "inference-fresh"
          "proxmox-root"
        ]))
      inventoryHostNames;

  missingInventoryHosts =
    builtins.filter (name: !(builtins.hasAttr name libHosts)) hostNamesExpectedInLib;
in
{
  inherit inventoryHostNames hostNamesExpectedInLib missingInventoryHosts;
  routerBackupInLib = builtins.hasAttr "router-backup" libHosts;
  routerBackupInInventory = builtins.hasAttr "router-backup" inventoryHosts;
}
