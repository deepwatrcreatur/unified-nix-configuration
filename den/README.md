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
