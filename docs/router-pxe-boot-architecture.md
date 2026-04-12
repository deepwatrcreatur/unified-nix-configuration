# Router PXE Boot Architecture

This note defines the preferred module boundary for PXE/netboot support in the
router stack and scopes the first implementation slice.

## Current State

- The active router host currently uses Technitium as the DHCP provider via
  [`services.router-technitium.scopes`](../hosts/nixos/router/networking.nix).
- `nix-router-optimized` already contains a reusable `router-dhcp` module built
  on `systemd-networkd`.
- That `router-dhcp` module already exposes raw `[DHCPServer]` passthrough via
  `services.router-dhcp.interfaces.<name>.extraDhcpServerConfig`.
- Local `systemd-networkd` on this host supports `BootServerAddress=`,
  `BootServerName=`, and `BootFilename=` in `[DHCPServer]` (`systemd 258`).

## Recommendation

The durable PXE configuration surface should live in `nix-router-optimized`,
not only in this config repo.

Reasoning:

- PXE boot advertisement is fundamentally a DHCP-server capability, not a
  host-specific one-off.
- The reusable router flake already owns the generic DHCP abstraction
  (`router-dhcp`) and is the natural place for typed PXE options.
- Keeping the schema upstream avoids baking Technitium-specific semantics into
  this repo's host role.
- Multiple backends may eventually need to implement the same model:
  `router-dhcp` now, `router-kea` later, and possibly a temporary
  Technitium-backed bridge during migration.

## Ownership Split

### `nix-router-optimized`

Own the reusable PXE data model and generic DHCP-facing behavior:

- typed PXE options under the DHCP module
- translation of those options into backend-specific DHCP settings
- backend-neutral validation such as:
  - `bootServerAddress` xor `bootServerName` recommendation
  - non-empty boot filename/URL when PXE is enabled
  - per-segment enablement keyed to routed interfaces

Proposed shape for the first upstream slice:

```nix
services.router-dhcp.interfaces.lan.pxe = {
  enable = true;
  bootServerAddress = "10.10.10.1";
  bootFilename = "/netboot/ipxe.efi";
  # optional
  bootServerName = "router";
};
```

This can initially compile down to `BootServerAddress=`, `BootServerName=`, and
`BootFilename=` inside `extraDhcpServerConfig`.

### `unified-nix-configuration`

Own deployment-specific policy and any transitional backend glue:

- which routed segments or VLANs should advertise PXE
- firewall allowances and service placement for the chosen artifact server
- boot artifact storage paths and operator docs
- any temporary Technitium-specific syncing if the current router remains on
  Technitium DHCP before Kea or `router-dhcp` becomes the active DHCP engine

In other words: the host repo should choose where PXE is enabled, but the
router flake should define what "PXE configuration" means.

## Transitional Reality

There are two different time horizons:

### Long-term target

Move PXE option modeling into `nix-router-optimized` and keep this repo focused
on host policy.

### Near-term compatibility

Because the current router still declares Technitium DHCP scopes locally, the
first runnable deployment may require repo-local glue that applies the same PXE
values to Technitium-managed scopes.

That glue should be treated as transitional, not the canonical design. The
schema should still be shaped for eventual reuse by `router-dhcp` and
`router-kea`.

## Delivery Path Recommendation

The first implementation slice should not start with iVentoy.

Instead, the first slice should support plain DHCP PXE advertisement for a
single routed segment, using either:

- a boot filename served by an existing TFTP/HTTP endpoint, or
- a simple repo-owned boot artifact service added later

Why this is the right first slice:

- the DHCP-side enablement is already the narrowest missing capability
- it validates the module boundary before introducing a full menu/ISO platform
- it remains useful even if iVentoy is later adopted as the serving layer

## BIOS / UEFI Position

The design should assume UEFI-first for the initial supported path.

Reasoning:

- modern homelab hardware is more likely to boot cleanly via UEFI
- UEFI HTTP/iPXE style flows are easier to evolve than legacy BIOS/TFTP-only
  assumptions
- BIOS support often introduces menu-loader branching and client-class logic
  that would expand the first PR too much

BIOS compatibility should remain a documented follow-up question, not a blocker
for the initial module boundary.

## iVentoy Position

iVentoy should be evaluated as an optional serving layer, not as the initial
module boundary.

It may become a good answer for operator-friendly ISO boot workflows, but it
should sit behind the DHCP/PXE configuration model rather than define it.

That means the architecture sequence should be:

1. define reusable PXE DHCP options
2. implement one simple delivery path
3. evaluate whether iVentoy is worth adding as an optional serving backend

## First Implementation PR

The first implementation PR should:

1. add typed PXE options to `nix-router-optimized` `router-dhcp`
2. compile them into `systemd-networkd` DHCP server settings
3. document one UEFI-first example for a LAN or lab VLAN
4. keep the feature disabled by default

If the current router must stay on Technitium DHCP in the short term, a second,
repo-local follow-up PR can map the same values into Technitium scope config or
sync logic without changing the durable schema.

## Answer To The Practical Question

PXE enablement should be split:

- the reusable PXE option model belongs in the router flake
  (`nix-router-optimized`)
- the decision to enable it on this homelab router, and any temporary
  Technitium-specific bridge, belongs in this config repo

That is the cleanest path that works now without locking the design to the
current DHCP backend.
