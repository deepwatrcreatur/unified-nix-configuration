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
  moduleLoadingEval = import ../tests/module-loading-eval.nix { lib = pkgs.lib; };
  sshKeysManagerEval = import ../tests/ssh-keys-manager-eval.nix {
    lib = pkgs.lib;
    inherit pkgs;
  };

  names = builtins.attrNames;
  inventoryHostNames = names inventoryHosts;
  inventoryHomeNames = names inventoryHomes;
  legacyHostAllowlist = [
    "gateway"
    "inference-fresh"
  ];

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

  missingInventoryHostPaths =
    builtins.filter (name: !builtins.pathExists inventoryHosts.${name}.hostPath) inventoryHostNames;

  legacyHostNames =
    builtins.filter (name: inventoryHosts.${name}.mode or "" == "legacy") inventoryHostNames;

  unexpectedLegacyHosts =
    builtins.filter (name: !(builtins.elem name legacyHostAllowlist)) legacyHostNames;

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

  homeMissingUserPaths =
    builtins.concatLists (
      pkgs.lib.mapAttrsToList
        (name: home:
          if home ? userPath && !builtins.pathExists home.userPath then [ "${name}:userPath" ] else [ ])
        inventoryHomes
    );

  homeMissingModulePaths =
    builtins.concatLists (
      pkgs.lib.mapAttrsToList
        (name: home:
          if home ? modules then
            map (path: "${name}:${toString path}") (builtins.filter (path: !builtins.pathExists path) home.modules)
          else
            [ ])
        inventoryHomes
    );

  ips =
    builtins.filter (ip: ip != null)
      (map (name: libHosts.${name}.ip or null) (names libHosts));

  uniqueIps = builtins.attrNames (builtins.listToAttrs (map (ip: { name = ip; value = true; }) ips));

  duplicateIpsExist = builtins.length uniqueIps != builtins.length ips;

  # Collect all service names (from the `services` field) across every host.
  # A service name must not collide with a machine hostname to avoid ambiguity
  # like "authentik" (service) vs "authentik-host" (machine) — they are different,
  # but a collision would mean a CNAME and an A record share the same label.
  allLibHostNames = names libHosts;

  serviceNameCollisions =
    builtins.concatLists (
      map
        (hostName:
          let
            serviceNames = libHosts.${hostName}.services or [];
          in
          builtins.filter (svc: builtins.elem svc allLibHostNames) serviceNames)
        allLibHostNames
    );

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
    ++ (if missingInventoryHostPaths != [ ] then
      [ "den inventory hosts point at missing hostPath values: ${builtins.concatStringsSep ", " missingInventoryHostPaths}" ]
    else
      [ ])
    ++ (if missingDenInventoryHosts != [ ] then
      [ "Managed infrastructure hosts missing from den inventory: ${builtins.concatStringsSep ", " missingDenInventoryHosts}" ]
    else
      [ ])
    ++ (if unexpectedLegacyHosts != [ ] then
      [ "Unexpected legacy-mode hosts remain in den inventory: ${builtins.concatStringsSep ", " unexpectedLegacyHosts}" ]
    else
      [ ])
    ++ (if missingProxmoxLeaves != [ ] then
      [ "Proxmox hosts missing home leaves in den/inventory/homes.nix: ${builtins.concatStringsSep ", " missingProxmoxLeaves}" ]
    else
      [ ])
    ++ (if homeMissingUserPaths != [ ] then
      [ "den home entries point at missing userPath values: ${builtins.concatStringsSep ", " homeMissingUserPaths}" ]
    else
      [ ])
    ++ (if homeMissingModulePaths != [ ] then
      [ "den home entries reference missing module paths: ${builtins.concatStringsSep ", " homeMissingModulePaths}" ]
    else
      [ ])
    ++ (if unknownAspectRefs != [ ] then
      [ "Aspect-based hosts reference unknown den aspects: ${builtins.concatStringsSep ", " unknownAspectRefs}" ]
    else
      [ ])
    ++ (if duplicateIpsExist then [ "Duplicate IP addresses detected in lib/hosts.nix" ] else [ ])
    ++ (if serviceNameCollisions != [ ] then
      [ "Service names in lib/hosts.nix collide with machine hostnames (a CNAME and an A record cannot share a label): ${builtins.concatStringsSep ", " serviceNameCollisions}" ]
    else
      [ ]);

  checkBody =
    if failMessages != [ ] then
      builtins.throw (builtins.concatStringsSep "\n" failMessages)
    else
      pkgs.writeText "inventory-consistency.txt" ''
        inventory-consistency=ok
        checked-hosts=${toString (builtins.length hostNamesExpectedInLib)}
        checked-proxmox-leaves=${toString (builtins.length proxmoxHostNames)}
        checked-legacy-hosts=${toString (builtins.length legacyHostNames)}
        checked-den-aspect-hosts=${toString (
          builtins.length (builtins.filter (name: inventoryHosts.${name}.mode or "" == "aspect") inventoryHostNames)
        )}
      '';
in
{
  checks.x86_64-linux.inventory-consistency = checkBody;
  checks.x86_64-linux.module-loading-eval = pkgs.writeText "module-loading-eval.txt" (
    if moduleLoadingEval == [ ] then "module-loading-eval=ok\n" else builtins.throw "module-loading-eval failed"
  );
  checks.x86_64-linux.ssh-keys-manager-eval = pkgs.writeText "ssh-keys-manager-eval.txt" (
    if sshKeysManagerEval == [ ] then "ssh-keys-manager-eval=ok\n" else builtins.throw "ssh-keys-manager-eval failed"
  );
}
