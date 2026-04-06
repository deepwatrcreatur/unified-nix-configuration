# Host Metadata Boundary: lib/hosts.nix vs den/inventory

This document describes the intentional authority split between the two host
metadata files in this repo and gives guidance for keeping them in sync.

## Authority Split

### lib/hosts.nix

Owns **operational and network-layer metadata**:

- IPv4/IPv6 addresses and DHCP reservations (MAC address, scope)
- SSH access configuration (sshHostname, sshUser, includeSsh)
- DNS registration (includeDns, aliases)
- Public ingress routing (publicIngressServices, ddnsServices)
- Internal admin service ports (internalAdminServices)
- Human-readable descriptions
- Shared network CIDR definitions (networks.lan, networks.management)

This file is consumed by DNS zone generation, SSH config templating, and
Ansible inventory tooling. It does not control what NixOS configuration is
built for a host.

### den/inventory/hosts.nix

Owns **NixOS build composition metadata**:

- system architecture (x86_64-linux, aarch64-linux)
- hostPath — path to the host's NixOS configuration directory
- mode — composition strategy ("aspect" or "legacy")
- aspectsList — ordered list of aspects assembled into the NixOS config
- kind — output type ("nixos", "darwin", "home")

This file is consumed by lib/flake/inventory-outputs.nix to produce
nixosConfigurations (and homeConfigurations/darwinConfigurations). It does
not carry any network or SSH metadata.

## Alignment Checks

outputs/checks.nix enforces consistency between the two files:

- Every host in den/inventory/hosts.nix (except an explicit allowlist) must
  also appear in lib/hosts.nix.
- If a host is present in inventory but missing from lib/hosts.nix, the check
  outputs a failing derivation with a descriptive error.
- Legacy mode hosts are tracked separately and must be on an allowlist to
  avoid blocking the build.

These checks are the primary drift-detection mechanism. They do not prevent
drift in the other direction (a host in lib/hosts.nix with no inventory
entry), but such hosts are harmlessly ignored by the build system.

## Drift-Prone Edge: Host Renaming

The most common source of drift is renaming a host. Because the hostname is
the key in both files, a rename requires updating:

1. The attribute name in den/inventory/hosts.nix
2. The `name` field inside that attribute
3. The attribute name in lib/hosts.nix
4. The hostPath directory name (hosts/<name>)

The alignment check in outputs/checks.nix will catch a mismatch between
steps 1 and 3 at evaluation time. Steps 2 and 4 are not automatically
validated and must be updated manually.

## Guidance for Future Agents

**Adding a new host:**
1. Add the entry to den/inventory/hosts.nix with kind, system, hostPath, mode,
   and aspectsList.
2. Add a corresponding entry to lib/hosts.nix with at minimum an ip and
   description. Set includeDns/includeSsh as appropriate.
3. Create the host directory at the path referenced by hostPath.

**Adding metadata to an existing host:**
- Network/SSH/DNS/ingress metadata -> lib/hosts.nix
- NixOS composition changes (new aspect, architecture change) -> den/inventory/hosts.nix

**Do not add** NixOS build fields (hostPath, aspectsList, system) to
lib/hosts.nix, and do not add networking fields (ip, sshUser, aliases) to
den/inventory/hosts.nix. Keeping the boundary clean avoids requiring consumers
of each file to parse fields they do not understand.
