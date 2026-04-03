# VPN Module Hardening And Tests

Status: `done`
Suggested branch: `docs/router-vpn-module-hardening`
Priority: `medium`

## Goal

Turn the recent router VPN module review feedback into explicit upstream work
items for `nix-router-optimized`.

## Why This Matters

Recent feedback on the new `router-tailscale`, `router-wireguard`, and
`router-openvpn` modules surfaced a real next sprint:

- add evaluation/integration checks
- add guardrails for silent `routeToWan` no-op cases
- validate multi-instance OpenVPN interface names
- centralize WAN-derivation helper logic
- add a small module-selection decision matrix

## Tasks

- split the feedback into 3-5 PR-sized upstream tasks
- rank them by value and implementation order
- identify which tasks should be docs-only versus test/module changes

## Deliverable

Expand this file with:

- a ranked task list
- suggested branch names
- suggested test scope
- which parts belong upstream versus local repo docs

## Do Not

- do not mix router-fleet work with upstream router-flake work invisibly
- do not implement all fixes in one giant PR
