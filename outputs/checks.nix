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
    "lattitude"
    "418"
    "420"
    "atiyas-airport-extreme"
    "ap-nosheen-bedroom"
    "ap-nosheen-living"
    "ap-ruqayya"
    "apt-cache"
    "homeassistant"
    "infisical"
    "scrypted-lxc"
    "sw-cisco-sg300-52p"
    "sw-dell-n1124t-on"
    "sw-dell-powerconnect"
    "sw-hp-2910al-48g-poe"
    "sw-main"
    "synology-dsm"
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

  duplicateIpExemptHosts = [
    "homeassistant" # Container co-located on podman host (10.10.11.84)
  ];

  checkHostNamesForIps =
    builtins.filter (name: !(builtins.elem name duplicateIpExemptHosts)) (names libHosts);

  ips =
    builtins.filter (ip: ip != null)
      (map (name: libHosts.${name}.ip or null) checkHostNamesForIps);

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

  # Collect all public ingress service names across every host.
  # A service name must not collide with a machine hostname to avoid ambiguity
  # like "authentik" (service) vs "authentik-host" (machine) — they are different,
  # but a collision would mean a CNAME and an A record share the same label.
  allLibHostNames = names libHosts;
  publicIngressServicesFor =
    hostName: libHosts.${hostName}.publicIngressServices or libHosts.${hostName}.services or [ ];
  internalAdminServicesFor =
    hostName:
    builtins.attrNames (libHosts.${hostName}.internalAdminServices or { });

  serviceNameCollisions =
    builtins.concatLists (
      map
        (hostName:
          builtins.filter (svc: builtins.elem svc allLibHostNames) (publicIngressServicesFor hostName))
        allLibHostNames
    );

  routerPublicIngressServices = publicIngressServicesFor "router";
  routerInternalAdminServices = internalAdminServicesFor "router";
  routerExpectedCaddyVirtualHostNames = routerPublicIngressServices ++ routerInternalAdminServices;
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
    builtins.filter (name: !(builtins.elem name routerCaddyVirtualHostNames)) routerExpectedCaddyVirtualHostNames;

  routerCaddyHostsMissingInInventory =
    builtins.filter
      (name:
        !(builtins.elem name routerExpectedCaddyVirtualHostNames)
        && !(builtins.elem name (builtins.attrNames (libHosts.router.internalAdminServices or { }))))
      routerCaddyVirtualHostNames;

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

  # INVARIANT: the router's standby specialisation hands every single-active
  # LAN service and 10.10.10.1 to elitedesk, and keeps the WAN down
  # (docs/router-source-of-truth.md#manual-failover-specialisations).
  routerStandby =
    let
      inherit (pkgs) lib;
      scriptText = a: if builtins.isString a then a else a.text;
      base = inputs.self.nixosConfigurations.router.config;
      sb = base.specialisation.standby.configuration;
      nets = sb.systemd.network.networks;
      # GOTCHA: networkd applies the first file (by name) whose [Match]
      # names the device; a file without [Match] (role.nix's 08-router-parent)
      # is ignored. Check the file that actually applies (rehearsal 2).
      lanFiles = cfg: lib.sort (a: b: a < b) (builtins.attrNames (lib.filterAttrs (_: n: (n.matchConfig.Name or null) == "enp6s16") cfg.systemd.network.networks));
      effLan = cfg: cfg.systemd.network.networks.${builtins.head (lanFiles cfg)};
      lanNet = effLan sb;
      # GOTCHA: a timer defined without a trigger is rejected by systemd
      # ("bad unit file setting") and makes switch-to-configuration exit 4.
      untriggered =
        cfg:
        builtins.attrNames (
          lib.filterAttrs (
            _: t:
            t.enable
            && !(lib.any (k: lib.hasPrefix "On" k && !builtins.elem t.timerConfig.${k} [ "" [ ] null false ]) (builtins.attrNames t.timerConfig))
          ) cfg.systemd.timers
        );
      failures = builtins.filter (f: !f.ok) [
        { ok = nets."10-router-wan-primary".linkConfig.ActivationPolicy == "always-down"; msg = "standby WAN must be always-down"; }
        { ok = sb.services.router-networking.routedInterfaces.lan.ipv4Address == "10.10.10.2/16"; msg = "standby LAN address must be 10.10.10.2/16"; }
        { ok = lanNet.address == [ "10.10.10.2/16" ] && lanNet.gateway == [ "10.10.10.1" ]; msg = "standby's active LAN network must drop 10.10.10.1 and route via elitedesk"; }
        { ok = !(lanNet.networkConfig.IPv6SendRA or false) && !(lanNet.networkConfig.DHCPPrefixDelegation or false); msg = "standby must not send RAs or delegate prefixes"; }
        { ok = sb.users.groups ? kea; msg = "standby must keep the kea group for the agenix TSIG secret"; }
        { ok = !sb.services.kea.dhcp4.enable && !sb.services.kea.dhcp-ddns.enable; msg = "standby must not run Kea"; }
        { ok = !sb.services.inadyn.enable && !sb.services.miniupnpd.enable; msg = "standby must not run DDNS or UPnP"; }
        { ok = untriggered sb == [ ]; msg = "standby timers without a trigger: ${builtins.concatStringsSep ", " (untriggered sb)}"; }
        { ok = untriggered base == [ ]; msg = "primary timers without a trigger: ${builtins.concatStringsSep ", " (untriggered base)}"; }
        { ok = builtins.elem "systemd-networkd.service" base.systemd.services.router-failover-boot-guard.before; msg = "the demoted-boot guard must run before networkd"; }
        { ok = base.systemd.services.kea-dhcp4-server.unitConfig.ConditionPathExists or null == "!/run/router-failover/demoted" && builtins.elem "kea-dhcp4-server.service" base.systemd.services.router-failover-boot-guard.before; msg = "Kea must wait for the guard and not start on a demoted boot"; }
        { ok = lib.hasInfix "touch /var/lib/router-failover/demoted" (scriptText sb.system.activationScripts.routerFailoverRole); msg = "standby activation must set the demoted marker"; }
        { ok = lib.hasInfix "switch|test)" (scriptText base.system.activationScripts.routerFailoverRole); msg = "only a switch or test to primary may clear the demoted marker"; }
        { ok = !sb.systemd.services.router-failover-resume-standby.enable; msg = "standby must not re-run its own activation"; }
        { ok = !(builtins.elem "10.10.10.1" sb.services.router-snmp.listenAddresses); msg = "standby snmpd must not bind 10.10.10.1"; }
        { ok = lanFiles sb == lanFiles base && lanFiles base != [ ]; msg = "primary and standby must apply the same LAN network file"; }
        { ok = !sb.systemd.services.health-wan-carrier.enable && !sb.systemd.services.health-wan-ip.enable; msg = "standby must not run WAN health probes (they fail by design and fail activation)"; }
        { ok = !base.systemd.services.router-failover-boot-guard.restartIfChanged; msg = "a role switch must not re-run the demoted-boot guard"; }
        { ok = base.services.kea.dhcp4.enable && (effLan base).address == [ "10.10.10.1/16" ] && (effLan base).networkConfig.IPv6SendRA or false; msg = "the default router configuration must stay primary"; }
      ];
    in
    if failures != [ ] then
      builtins.throw ("router-standby-specialisation: " + builtins.concatStringsSep "; " (map (f: f.msg) failures))
    else
      pkgs.writeText "router-standby-specialisation.txt" "router-standby-specialisation=ok\n";
in
{
  checks.x86_64-linux.router-standby-specialisation = routerStandby;
  checks.x86_64-linux.inventory-consistency = checkBody;
  # beads-q survives a fetch that briefly misses the queue branch (the race
  # seen in nix-clan-homelab nch-a9a.9) and still fails when it is really gone.
  # nch-a67.7: nix-user-config never writes a placeholder or junk token.
  checks.x86_64-linux.nix-user-config-secret =
    let
      fnoxStub = pkgs.writeShellScript "fnox" ''
        printf '%s\n' "$*" >> "$STUB_LOG"
        if [ -n "''${GITHUB_TOKEN:-}" ]; then echo "ambient-$GITHUB_TOKEN"; exit 0; fi
        case "$STUB_MODE" in
          age) echo age ;;
          good) echo "$STUB_VALUE" ;;
          fail) echo "decrypt error" >&2; exit 1 ;;
        esac
      '';
    in
    pkgs.runCommand "nix-user-config-secret" { } ''
      set -euo pipefail
      export STUB_LOG=$PWD/log
      : > "$STUB_LOG"
      gh="ghp_$(printf 'x%.0s' $(seq 36))"
      other="ghp_$(printf 'y%.0s' $(seq 36))"
      jwt="$(printf 'a%.0s' $(seq 40)).$(printf 'b%.0s' $(seq 20))"
      printf '%s\n' "$gh" > good-file
      printf 'Error: failed to decrypt\ncheck your key\n' > bad-file
      NUC_FNOX=${fnoxStub} NUC_FNOX_CONFIG=/cfg/config.toml NUC_FNOX_AGE_KEY_FILE=/id
      source ${../modules/home-manager/common/nix-user-config-secret.sh}
      expect() { [ "$1" = "$2" ] || { echo "FAIL: $3"; exit 1; }; }

      export STUB_MODE=age
      expect "$(nuc_secret github GITHUB_TOKEN good-file 2>err)" "$gh" "fnox 'age' is ignored, file used"
      grep -q 'does not look like a github token' err
      grep -q -- '-c /cfg/config.toml --if-missing error get GITHUB_TOKEN' "$STUB_LOG"

      expect "$(nuc_secret github GITHUB_TOKEN bad-file 2>err)" "" "age plus a junk file writes nothing"
      grep -q 'does not hold a valid github token' err
      if grep -q 'decrypt' err; then echo "FAIL: file contents leaked to stderr"; exit 1; fi

      export STUB_MODE=good STUB_VALUE=$other
      expect "$(nuc_secret github GITHUB_TOKEN good-file)" "$other" "valid fnox value wins"
      expect "$(GITHUB_TOKEN=$gh; export GITHUB_TOKEN; nuc_secret github GITHUB_TOKEN good-file)" "$other" "ambient GITHUB_TOKEN not passed to fnox"

      export STUB_MODE=fail
      expect "$(nuc_secret github GITHUB_TOKEN good-file)" "$gh" "fnox failure falls back to file"
      expect "$(nuc_secret github GITHUB_TOKEN missing-file)" "" "nothing available"

      export STUB_MODE=good STUB_VALUE=$jwt
      expect "$(nuc_secret token ATTIC_CLIENT_JWT_TOKEN "")" "$jwt" "netrc token accepted"
      export STUB_VALUE=short
      expect "$(nuc_secret token ATTIC_CLIENT_JWT_TOKEN "" 2>/dev/null)" "" "short value rejected"

      : > "$STUB_LOG"
      NUC_FNOX=""
      expect "$(nuc_secret github GITHUB_TOKEN good-file)" "$gh" "fnox off: file only"
      [ ! -s "$STUB_LOG" ] || { echo "FAIL: fnox called while off"; exit 1; }
      touch $out
    '';

  checks.x86_64-linux.beads-queue-fetch-retry =
    pkgs.runCommand "beads-queue-fetch-retry" { nativeBuildInputs = [ pkgs.beads-queue pkgs.git ]; } ''
      export HOME=$TMPDIR/home GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
      mkdir -p "$HOME"
      git init -q --bare remote.git
      git clone -q remote.git seed 2>/dev/null && cd seed
      git checkout -q --orphan beads-queue && mkdir .beads
      printf 'issue_prefix: tst\n' > .beads/config.yaml
      printf '%s\n' '{"id":"tst-a","title":"a","status":"open","priority":2,"issue_type":"task","created_at":"2026-11-26T00:00:00Z","updated_at":"2026-11-26T00:00:00Z"}' > .beads/issues.jsonl
      git add .beads && git commit -q -m seed && git push -q origin beads-queue
      cd .. && git clone -q remote.git src 2>/dev/null && git -C src commit -q --allow-empty -m code

      # The branch vanishes, as during a concurrent ref update, and comes back
      # only after beads-q has seen a failed fetch (not on a timer, which a
      # slow builder could outrun).
      mv remote.git/refs/heads/beads-queue ref.saved
      touch err
      (
        for _ in $(seq 1 600); do grep -q 'retrying (1/' err && break; sleep 0.05; done
        mv ref.saved remote.git/refs/heads/beads-queue
      ) &
      BEADS_Q_FETCH_RETRIES=20 beads-q -C src ready --json > out 2> err
      wait
      grep -q tst-a out
      grep -q 'retrying (1/' err

      # A non-numeric retry count is refused instead of looping forever.
      if BEADS_Q_FETCH_RETRIES=abc beads-q -C src ready --json 2> err3; then echo "expected failure" >&2; exit 1; fi
      grep -q 'must be positive integers' err3

      # Really gone: fails with a clear message instead of hanging.
      git -C remote.git update-ref -d refs/heads/beads-queue
      if beads-q -C src ready --json 2> err2; then echo "expected failure" >&2; exit 1; fi
      grep -q 'failed 5 times; giving up' err2
      touch $out
    '';

  checks.x86_64-linux.agent-guard-policy = pkgs.runCommand "agent-guard-policy" { nativeBuildInputs = [ pkgs.python3 ]; } ''
    python3 -I ${../tests/agent-guard-test.py} ${../scripts/agent-guard.py} | tee $out
  '';
  checks.x86_64-linux.module-loading-eval = pkgs.writeText "module-loading-eval.txt" (
    if moduleLoadingEval == [ ] then "module-loading-eval=ok\n" else builtins.throw "module-loading-eval failed"
  );
  checks.x86_64-linux.ssh-keys-manager-eval = pkgs.writeText "ssh-keys-manager-eval.txt" (
    if sshKeysManagerEval == [ ] then "ssh-keys-manager-eval=ok\n" else builtins.throw "ssh-keys-manager-eval failed"
  );
}
