# Den Architecture

`den/` is the primary inventory and composition layer for this repository.

It is den-inspired, but implemented locally for this flake rather than importing
`vic/den` directly. The structure is:

- `den/inventory/`: leaf inventory for NixOS, Home Manager, Darwin, and bootstrap outputs
- `den/aspects/`: reusable cross-cutting concerns such as `lxc-core`, `attic-client`, and `workstation-desktop`
- `den/hosts/`: thin host leaves that compose aspects and inject host-local hardware or networking
- `den/framework.nix` and `den/lib.nix`: helpers for turning inventory and aspect lists into flake outputs

The intent is:

- keep machine leaves small
- bundle shared behavior as named aspects
- keep generic modules in `modules/`
- keep opinionated shared bundles in `profiles/`
- let `den/inventory` drive the exported outputs in [`outputs/den.nix`](/home/deepwatrcreatur/flakes/unified-nix-configuration/outputs/den.nix)

Some hosts are still transitional:

- `mode = "aspect"` means the leaf is composed directly from `den/aspects`
- `mode = "legacy"` means the output is still backed by a legacy host tree, even though the inventory now lives under `den/`

That split is intentional while the migration continues, but the source of truth for exported
outputs should be treated as `den/inventory`, not `inventory/legacy`.

## Adding A Host

1. Add machine facts in [`lib/hosts.nix`](/home/deepwatrcreatur/flakes/unified-nix-configuration/lib/hosts.nix) if the host participates in SSH, DNS, or shared infra metadata.
2. Add the leaf in `den/inventory/hosts.nix`, `den/inventory/homes.nix`, or `den/inventory/darwin.nix`.
3. For aspect-based hosts, add `den/hosts/<name>/default.nix` and compose the required aspects there.
4. Keep host-only hardware and networking local to the leaf; keep reusable behavior in `den/aspects/`, `profiles/`, or `modules/`.

## Current Debt

- Some `den` leaves still import legacy host-local files for hardware and networking.
- Some exported leaves remain `mode = "legacy"` while their inventory is already under `den/`.
- Support metadata such as SSH and DNS still lives in [`lib/hosts.nix`](/home/deepwatrcreatur/flakes/unified-nix-configuration/lib/hosts.nix), so checks must keep `den/inventory` and `lib/hosts.nix` aligned.

## Active vs Legacy Paths

- Inference VMs now use `den/hosts/<name>/default.nix` plus den aspects as the
  active source of truth for exported `.#inference*` outputs.
- The old `hosts/nixos/inference-vm/hosts/*/default.nix` files are legacy and
  should not receive active fixes unless they are being migrated or deleted.
- Router leaves are still intentionally hybrid: den owns the exported leaf,
  while `den/hosts/router*.nix` still import legacy router host-local files for
  hardware, networking, Caddy, and configuration until that migration is split
  into reviewable PRs.

## Router source-of-truth map

For the `router` and `router-backup` hosts, the current ownership is:

- **den leaves (active)**
  - `den/hosts/router/default.nix`
  - `den/hosts/router-backup/default.nix`

- **Hardware (active, legacy host-local)**
  - `hosts/nixos/router/hardware-configuration.nix`
  - `hosts/nixos/router-backup/hardware-configuration.nix`

- **Networking (active, shared role logic)**
  - `hosts/nixos/router/networking.nix` (shared router role and DNS topology)
  - `hosts/nixos/router-backup/networking.nix` (imports `../router/networking.nix`, overrides hostname only)

- **Caddy / ingress and DNS**
  - Primary HTTPS ingress: `hosts/nixos/router/caddy.nix` (Caddy and public-facing routes)
  - Router-backup DNS and NAT toggle: `hosts/nixos/router-backup/caddy.nix` (enables `services.router-dns-service`, keeps NAT disabled)

- **Shared router role**
  - `hosts/nixos/router/role.nix` (imported by `hosts/nixos/router/configuration.nix` and `hosts/nixos/router-backup/configuration.nix`)

- **User host overlays**
  - `users/deepwatrcreatur/hosts/router/default.nix`
  - `users/deepwatrcreatur/hosts/router-backup/default.nix`

- **den inventory and aspects**
  - `den/inventory/hosts.nix` entries for `router` / `router-backup`
  - aspects referenced from those inventory entries and user host overlays.

Guidance for new changes:

- Prefer `den/hosts/router*.nix`, `den/inventory/*`, `den/aspects/*`, and
  `users/deepwatrcreatur/hosts/router*` for new behavior.
- Treat `hosts/nixos/router*/` files as transitional: they are still active
  today but are migration candidates; avoid adding new features there unless the
  change is explicitly part of a migration PR.
