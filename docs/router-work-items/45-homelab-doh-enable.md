# 45 — Homelab DoH Enablement

Status: `in-progress`
Suggested branch: `feat/router-homelab-doh`
Priority: `medium`

## Goal

Turn on the best encrypted-DNS mode for the actual homelab router after the
upstream option surface is merged.

## Current Recommendation

Use **DoH as the primary encrypted DNS mode** for the homelab.

Why:

- broadest support across browsers, Apple devices, and managed clients
- easiest client story when paired with a dedicated resolver hostname such as
  `dns.<domain>`
- better long-term fit for a household network than a DoT-only rollout

Keep **DoT optional** as a secondary endpoint if it falls out naturally from the
certificate/port plan.

Current direction:

- preferred homelab hostname: `dns.<domain>`
- preferred HTTPS owner: **Caddy stays on `:443`**
- preferred client protocol: **DoH**
- optional later addition: DoT on `:853`

## Current Blocker

The live router already uses Caddy on `:443`, and Caddy already manages ACME
certificates for multiple `*.deepwatercreature.com` hosts.

Observed evidence:

- Caddy currently owns `:443` on the live router
- Technitium currently serves only plain DNS on `10.10.10.1:53`
- Caddy storage already contains issued certificates for existing subdomains
- upstream encrypted-DNS option work is now in progress in
  `nix-router-optimized#38`

So this item must choose one concrete homelab path:

1. give Technitium direct ownership of the DoH HTTPS listener, or
2. keep Caddy on `:443` and introduce a clean DoH front-end / reverse-proxy
   pattern that still uses Technitium as the resolver backend

Current recommendation: choose **(2)** unless a later proof shows native
Technitium DoH can sit cleanly behind the existing Caddy setup without awkward
port or certificate duplication.

This is separate from item `41`, which is the reusable upstream feature work.

## Tasks

- choose the homelab hostname:
  - recommended: `dns.<domain>`
- decide whether homelab DoH should be:
  - Technitium-native on the public HTTPS port
  - or fronted by Caddy with a clean upstream target
- decide certificate sourcing:
  - reuse existing ACME automation
  - or provision a dedicated PKCS#12/PFX bundle for Technitium
- if DoT is also enabled:
  - decide whether `:853` should be exposed on the LAN only or more broadly
- validate the chosen approach on `router-backup` first
- document client configuration for:
  - Apple devices
  - browsers
  - generic OS resolvers

## Validation

- homelab clients can resolve over DoH successfully
- plain DNS on `:53` still works for legacy clients
- enabling DoH does not break the existing router HTTPS/admin paths
- client configuration is documented in-repo, not only in chat history
