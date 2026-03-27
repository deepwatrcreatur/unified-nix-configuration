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

  denInventory = import ../den/inventory;
  inventoryHosts = denInventory.hosts;
  inventoryHomes = denInventory.homes;
  libHosts = (import ../lib/hosts.nix).hosts;
  denAspectRegistry = import ../den/aspects { lib = pkgs.lib; };

  names = builtins.attrNames;
  inventoryHostNames = names inventoryHosts;
  inventoryHomeNames = names inventoryHomes;

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

  managedInfraHosts =
    builtins.filter
      (
        name:
        let
          host = libHosts.${name};
        in
        (host.includeSsh or true) || (host.includeDns or true)
      )
      (names libHosts);

  allowedInfraOnlyHosts = [
    "apt-cache"
    "casaos"
    "homeassistant"
    "infisical"
    "nixoslxc"
    "npm"
  ];

  missingDenInventoryHosts =
    builtins.filter
      (
        name:
        !(builtins.elem name allowedInfraOnlyHosts)
        && !(builtins.elem name inventoryHostNames)
        && !(builtins.elem "${name}-root" inventoryHomeNames)
      )
      managedInfraHosts;

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

  aspectNames = builtins.attrNames denAspectRegistry;

  hostAspectLists =
    builtins.mapAttrs
      (_: host:
        if host.mode or "" == "aspect" then
          let
            hostModule = import host.hostPath;
            evaluated =
              if builtins.isFunction hostModule then
                hostModule { lib = pkgs.lib; }
              else
                hostModule;
          in
          evaluated.aspectsList or [ ]
        else
          [ ])
      inventoryHosts;

  unknownAspectRefs =
    builtins.concatLists (
      pkgs.lib.mapAttrsToList
        (name: hostAspects:
          map (aspectName: "${name}:${aspectName}")
            (builtins.filter (aspectName: !(builtins.elem aspectName aspectNames)) hostAspects))
        hostAspectLists
    );

  failMessages =
    (if missingInventoryHosts != [ ] then
      [ "den inventory hosts missing from lib/hosts.nix: ${builtins.concatStringsSep ", " missingInventoryHosts}" ]
    else
      [ ])
    ++ (if missingDenInventoryHosts != [ ] then
      [ "Managed infrastructure hosts missing from den inventory: ${builtins.concatStringsSep ", " missingDenInventoryHosts}" ]
    else
      [ ])
    ++ (if missingProxmoxLeaves != [ ] then
      [ "Proxmox hosts missing home leaves in den/inventory/homes.nix: ${builtins.concatStringsSep ", " missingProxmoxLeaves}" ]
    else
      [ ])
    ++ (if unknownAspectRefs != [ ] then
      [ "Aspect-based hosts reference unknown den aspects: ${builtins.concatStringsSep ", " unknownAspectRefs}" ]
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
        checked-den-aspect-hosts=${toString (
          builtins.length (builtins.filter (name: inventoryHosts.${name}.mode or "" == "aspect") inventoryHostNames)
        )}
      '';
in
{
  checks.x86_64-linux.inventory-consistency = checkBody;
}
