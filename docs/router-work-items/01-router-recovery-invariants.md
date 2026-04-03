# Router Recovery Invariants

Status: `ready`
Suggested branch: `fix/router-recovery-invariants`
Priority: `highest`

## Goal

Lock in the properties that made the router usable again so future refactors do
not regress them.

## Why This Matters

Recent failure mode:

- management stayed reachable
- LAN address disappeared when the production LAN NIC had no carrier
- Prometheus, Grafana, and Netdata cascaded into failure because they waited on
  `10.10.10.1`
- the dashboard then looked broadly broken even though the management plane was
  still usable

The immediate fix was:

- LAN static address exists without carrier
- dashboard/monitoring recover once the address exists
- the router is usable as a standby/dev box with production NICs unplugged

Those need to become explicit invariants.

## Required Invariants

- `router` and `router-backup` must boot into a debuggable state even if WAN
  and LAN cables are unplugged.
- Management IP must remain reachable independently of production data-plane
  NIC state.
- Production LAN static IP must be configured without carrier.
- Monitoring/dashboard services must not remain stuck in `activating` solely
  because the production LAN cable is unplugged.
- Dashboard must not show stale services removed from the declarative config.

## Current Relevant Files

- [`hosts/nixos/router/role.nix`](../../hosts/nixos/router/role.nix)
- [`hosts/nixos/router/configuration.nix`](../../hosts/nixos/router/configuration.nix)
- [`modules/common/nix-settings.nix`](../../modules/common/nix-settings.nix)

## Tasks

- Add checks or eval assertions for:
  - LAN `ConfigureWithoutCarrier = true`
  - qemu guest agent enabled on router VMs
  - serial console kernel param present for router VMs
  - dashboard service list excludes removed router-local services such as
    `podman`
- Add a short operator note to the router docs explaining the intended standby
  behavior.
- Confirm router-backup gets the same no-carrier LAN behavior if it is supposed
  to mirror the production router role.

## Validation

- `nix build .#nixosConfigurations.router.config.system.build.toplevel`
- `nix build .#nixosConfigurations.router-backup.config.system.build.toplevel`
- one eval/check proving the expected networkd option exists

## Do Not

- do not change production LAN identity
- do not make the router silently “healthy” when management is broken
