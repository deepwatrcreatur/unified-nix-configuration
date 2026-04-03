# Operational Diagnostics CLI (`router-diag`)

Status: `in-progress`
Suggested branch: `feat/router-diag-cli`
Priority: `medium`
Unblocks: improved operator workflow

## Goal

Create a simple, VyOS-inspired CLI helper (`router-diag`) that provides high-level status for interfaces, firewall rules, and VPNs, making it easier for operators to debug the router from the terminal.

## Why This Matters

While the `router-dashboard` is excellent for web-based monitoring, operators often need a quick "show" command while logged in via SSH, especially during recovery scenarios where the management plane is the only path.

## Tasks

- Design a simple bash or python script `router-diag` with subcommands like:
  - `show interfaces`: IP addresses and carrier status.
  - `show firewall`: Summary of active nftables chains and hits.
  - `show vpn`: WireGuard/Tailscale status.
  - `show health`: Explicit health check results (derived from Task 05).
- Package the script in `nix-router-optimized` or the local repo.
- Ensure the script is available in the router's `environment.systemPackages`.
- Document usage in `docs/ops.md`.

## Validation

- `router-diag` runs correctly on the router.
- Subcommands provide accurate and readable output.
- The tool is helpful during a simulated failure (e.g. unplugged WAN).

## Do Not

- do not attempt to create a configuration CLI (read-only diagnostics only).
- do not add complex dependencies; keep it a lightweight wrapper.
