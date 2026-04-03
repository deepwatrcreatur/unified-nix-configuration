# Router Kea Module Roadmap

Status: `in-progress`
Suggested branch: `docs/router-kea-module-roadmap`
Priority: `high`

## Goal

Define the upstream `nix-router-optimized` module shape for optional Kea
support so the router flake can offer it without making it the default path.

## Why This Matters

If this is going to be a real option for users, the module boundary should be
designed deliberately before implementation starts.

## Questions To Answer

- What should the module be called?
  - `router-kea`
  - `router-kea-ddns`
  - one module vs multiple composable modules
- Which settings belong in the upstream module versus the local repo?
- How should HA, DDNS, and DNS-server target settings be modeled?
- Which parts should remain disabled by default?

## Expected Scope

At minimum, the roadmap should cover:

- DHCPv4 basics
- DDNS integration
- optional HA modes
- local-DNS target configuration
- firewall / interface integration
- internal-only admin exposure

## Deliverable

Create a design note or expand this file with:

- proposed module boundaries
- candidate option schema
- what should be upstreamed first
- what should stay repo-local initially

## Do Not

- do not write the module in this task
- do not assume all users want Technitium specifically
- do not make Kea the new default path
