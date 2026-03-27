{
  inputs,
  commonNixpkgsConfig,
  commonOverlays,
  ...
}:
let
  pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    config = commonNixpkgsConfig;
    overlays = commonOverlays;
  };

  inventoryHosts = import ../inventory/legacy/hosts.nix;
  inventoryHomes = import ../inventory/legacy/homes.nix;
  libHosts = (import ../lib/hosts.nix).hosts;

  names = builtins.attrNames;

  hostNamesExpectedInLib =
    builtins.filter
      (name:
        !(builtins.elem name [
          "inference-fresh"
          "proxmox-root"
        ]))
      (names inventoryHosts);

  missingInventoryHosts =
    builtins.filter (name: !(builtins.hasAttr name libHosts)) hostNamesExpectedInLib;

  proxmoxHostNames =
    builtins.filter
      (name:
        let host = libHosts.${name}; in host.sshUser or "" == "root" && builtins.match "^pve-.*" name != null)
      (names libHosts);

  missingProxmoxLeaves =
    builtins.filter (name: !(inventoryHomes ? "${name}-root")) proxmoxHostNames;

  ips =
    builtins.filter (ip: ip != null)
      (map (name: libHosts.${name}.ip or null) (names libHosts));

  uniqueIps = builtins.attrNames (builtins.listToAttrs (map (ip: { name = ip; value = true; }) ips));

  duplicateIpsExist = builtins.length uniqueIps != builtins.length ips;

  failMessages =
    (if missingInventoryHosts != [ ] then
      [ "Inventory hosts missing from lib/hosts.nix: ${builtins.concatStringsSep ", " missingInventoryHosts}" ]
    else
      [ ])
    ++ (if missingProxmoxLeaves != [ ] then
      [ "Proxmox hosts missing home leaves in inventory/legacy/homes.nix: ${builtins.concatStringsSep ", " missingProxmoxLeaves}" ]
    else
      [ ])
    ++ (if duplicateIpsExist then [ "Duplicate IP addresses detected in lib/hosts.nix" ] else [ ]);

  checkBody =
    if failMessages != [ ] then
      builtins.throw (builtins.concatStringsSep "\n" failMessages)
    else
      pkgs.writeText "inventory-consistency.txt" ''
        inventory-consistency=ok
        checked-hosts=${toString (builtins.length hostNamesExpectedInLib)}
        checked-proxmox-leaves=${toString (builtins.length proxmoxHostNames)}
      '';
in
{
  checks.x86_64-linux.inventory-consistency = checkBody;
}
