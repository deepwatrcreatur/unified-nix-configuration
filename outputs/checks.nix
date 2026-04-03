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
  legacyHostAllowlist = [ ];

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
    "homeassistant"
    "infisical"
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

  # Check that every aspect-based den host has a machine-identity public key file.
  # Without a .pub file, machineRecipients returns [] for that host, meaning the
  # machine cannot decrypt its own agenix secrets (only the operator user can).
  machineIdentityLib = import ../lib/agenix-machine-identities.nix;

  aspectInventoryHostNames =
    builtins.filter
      (name: inventoryHosts.${name}.mode or "" == "aspect")
      inventoryHostNames;

  hostsMissingMachineIdentityKey =
    builtins.filter
      (name:
        let key = machineIdentityLib.readPublicKey name; in
        key == null || key == "")
      aspectInventoryHostNames;

  # Some aspect hosts are planned but do not exist yet; they should emit a notice
  # but must not block CI until their machine-identity keys are created.
  machineIdentityFutureHosts = [
    "inference-fresh"
    "inference2"
    "inference3"
    "phoenix"
    "router-bootstrap"
    "rustdesk"
  ];

  hostsMissingMachineIdentityKeyNow =
    builtins.filter (name: !(builtins.elem name machineIdentityFutureHosts)) hostsMissingMachineIdentityKey;

  # Collect all public ingress service names across every host.
  # A service name must not collide with a machine hostname to avoid ambiguity
  # like "authentik" (service) vs "authentik-host" (machine) — they are different,
  # but a collision would mean a CNAME and an A record share the same label.
  allLibHostNames = names libHosts;
  publicIngressServicesFor =
    hostName: libHosts.${hostName}.publicIngressServices or libHosts.${hostName}.services or [ ];

  serviceNameCollisions =
    builtins.concatLists (
      map
        (hostName:
          builtins.filter (svc: builtins.elem svc allLibHostNames) (publicIngressServicesFor hostName))
        allLibHostNames
    );

  routerPublicIngressServices = publicIngressServicesFor "router";
  routerDdnsServices = libHosts.router.ddnsServices or [ ];

  routerDdnsOutsideIngress =
    builtins.filter (name: name != "@" && !(builtins.elem name routerPublicIngressServices)) routerDdnsServices;

  routerCaddyFile = builtins.readFile ../hosts/nixos/router/caddy.nix;
  routerCaddyLiteralVirtualHostMatches =
    builtins.split "\n[[:space:]]*\"([a-z0-9-]+)\\.deepwatercreature\\.com\"[[:space:]]*=" routerCaddyFile;
  routerCaddyMkFqdnVirtualHostMatches =
    builtins.split "mkFqdn \"([a-z0-9-]+)\"" routerCaddyFile;
  matchCapturesToNames =
    matches:
    builtins.attrNames (
      builtins.listToAttrs (
        builtins.concatLists (
          map
            (
              part:
              if builtins.isList part then
                map (name: {
                  inherit name;
                  value = true;
                }) part
              else
                [ ]
            )
            matches
        )
      )
    );
  routerCaddyVirtualHostNames =
    builtins.attrNames (
      builtins.listToAttrs (
        map (name: {
          inherit name;
          value = true;
        }) ((matchCapturesToNames routerCaddyLiteralVirtualHostMatches) ++ (matchCapturesToNames routerCaddyMkFqdnVirtualHostMatches))
      )
    );

  routerIngressMissingInCaddy =
    builtins.filter (name: !(builtins.elem name routerCaddyVirtualHostNames)) routerPublicIngressServices;

  routerCaddyHostsMissingInInventory =
    builtins.filter (name: !(builtins.elem name routerPublicIngressServices)) routerCaddyVirtualHostNames;

  routerPrimaryHost = libHosts.router;
  routerBackupHost = libHosts.router-backup;
  routerPrimarySshTarget = routerPrimaryHost.sshHostname or routerPrimaryHost.hostname or routerPrimaryHost.ip or null;
  routerBackupSshTarget = routerBackupHost.sshHostname or routerBackupHost.hostname or routerBackupHost.ip or null;
  routerSpareModelIssues =
    (pkgs.lib.optional (routerPrimarySshTarget == null) "router is missing an SSH management target in lib/hosts.nix")
    ++ (pkgs.lib.optional (routerBackupSshTarget == null) "router-backup is missing an SSH management target in lib/hosts.nix")
    ++ (pkgs.lib.optional (routerPrimarySshTarget == routerBackupSshTarget) "router and router-backup must not share the same management SSH target")
    ++ (pkgs.lib.optional ((routerBackupHost.includeDns or true)) "router-backup must stay out of DNS inventory while it is a standby spare")
    ++ (pkgs.lib.optional ((routerBackupHost.ip or null) != null) "router-backup must not advertise a distinct production IP in lib/hosts.nix");

  aspectNames = builtins.attrNames denAspectRegistry;

  # Read aspectsList directly from inventory entries (aspect hosts must declare it there).
  # Previously this tried to evaluate the host module and read aspectsList from the result,
  # but mkHostModule returns { imports = [...]; } — a NixOS module — so aspectsList was
  # never present and every host silently got [].
  hostAspectLists =
    builtins.mapAttrs
      (_: host: host.aspectsList or [ ])
      inventoryHosts;

  # Assert that every aspect host using lxc-core has an explicit networking aspect.
  # lxc-core sets up the container base but deliberately does not configure networking,
  # so each LXC host must opt into a networking aspect.  Hosts that use externally
  # managed static IP (e.g. set by Proxmox) must be explicitly listed below.
  lxcStaticNetworkingHosts = [
    "podman"   # static IP assigned by Proxmox DHCP reservation
    "rustdesk" # static IP assigned by Proxmox DHCP reservation
  ];

  knownNetworkingAspects = [
    "lxc-dhcp-networking"
    "homeserver-networking"
  ];

  lxcHostsMissingNetworking =
    builtins.filter
      (name:
        let
          aspects = hostAspectLists.${name};
          hasLxcCore = builtins.elem "lxc-core" aspects;
          hasNetworkingAspect = builtins.any (a: builtins.elem a knownNetworkingAspects) aspects;
          isStaticException = builtins.elem name lxcStaticNetworkingHosts;
        in
        hasLxcCore && !hasNetworkingAspect && !isStaticException)
      aspectInventoryHostNames;

  # Non-LXC aspect hosts that are missing the "nixos-base" aspect.
  # nixos-base imports hosts/nixos/default.nix which sets the required base
  # (timezone, openssh defaults).  Hosts that provide equivalent coverage
  # through a specialised base aspect are listed in nixosBaseExemptHosts.
  nixosBaseExemptHosts = [
    # inference-vm-base imports hosts/nixos/inference-vm which provides its
    # own base configuration tailored for inference workloads.
    "inference1"
    "inference2"
    "inference3"
    "inference-fresh"
  ];

  nonLxcHostsMissingNixosBase =
    builtins.filter
      (name:
        let
          aspects = hostAspectLists.${name};
          hasLxcCore = builtins.elem "lxc-core" aspects;
          hasNixosBase = builtins.elem "nixos-base" aspects;
          isExempt = builtins.elem name nixosBaseExemptHosts;
        in
        !hasLxcCore && !hasNixosBase && !isExempt)
      aspectInventoryHostNames;

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
      [ ])
    ++ (if routerDdnsOutsideIngress != [ ] then
      [ "router.ddnsServices contains names that are not declared in router.publicIngressServices: ${builtins.concatStringsSep ", " routerDdnsOutsideIngress}" ]
    else
      [ ])
    ++ (if routerIngressMissingInCaddy != [ ] then
      [ "router.publicIngressServices are missing matching Caddy virtualHosts in hosts/nixos/router/caddy.nix: ${builtins.concatStringsSep ", " routerIngressMissingInCaddy}" ]
    else
      [ ])
    ++ (if routerCaddyHostsMissingInInventory != [ ] then
      [ "Caddy virtualHosts in hosts/nixos/router/caddy.nix are missing from router.publicIngressServices: ${builtins.concatStringsSep ", " routerCaddyHostsMissingInInventory}" ]
    else
      [ ])
    ++ (if routerSpareModelIssues != [ ] then routerSpareModelIssues else [ ])
    ++ (if lxcHostsMissingNetworking != [ ] then
      [ "LXC hosts use lxc-core without a networking aspect and are not in lxcStaticNetworkingHosts: ${builtins.concatStringsSep ", " lxcHostsMissingNetworking}" ]
    else
      [ ])
    ++ (if nonLxcHostsMissingNixosBase != [ ] then
      [ "Non-LXC aspect hosts missing the nixos-base aspect (add nixos-base or add to nixosBaseExemptHosts with justification): ${builtins.concatStringsSep ", " nonLxcHostsMissingNixosBase}" ]
    else
      [ ]);

  # Non-fatal notice embedded in the check output (not in failMessages).
  missingKeyNotice =
    if hostsMissingMachineIdentityKey != [ ] then
      "notice: aspect hosts without a machine-identity key (cannot self-decrypt agenix secrets): ${builtins.concatStringsSep ", " hostsMissingMachineIdentityKey}\n"
    else
      "";

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
        ${missingKeyNotice}
      '';
in
{
  inherit missingInventoryHosts;
  checks.x86_64-linux.inventory-consistency = checkBody;
  checks.x86_64-linux.module-loading-eval = pkgs.writeText "module-loading-eval.txt" (
    if moduleLoadingEval == [ ] then "module-loading-eval=ok\n" else builtins.throw "module-loading-eval failed"
  );
  checks.x86_64-linux.ssh-keys-manager-eval = pkgs.writeText "ssh-keys-manager-eval.txt" (
    if sshKeysManagerEval == [ ] then "ssh-keys-manager-eval=ok\n" else builtins.throw "ssh-keys-manager-eval failed"
  );
}
