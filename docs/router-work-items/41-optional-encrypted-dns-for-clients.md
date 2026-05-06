# 41 — Optional Encrypted DNS for Clients

Status: `ready`
Suggested branch: `feat/router-encrypted-dns`
Priority: `medium`

## Goal

Add a clean, optional encrypted-DNS feature set for LAN clients so flake users
can offer modern DNS privacy without making it mandatory for every router
deployment.

## Why This Matters

The current router setup serves plain DNS on `:53` via Technitium and does not
expose a first-class encrypted resolver surface for clients.

That is acceptable for a working homelab router, but it is a missing product
feature for a reusable router flake:

- some users want the common encrypted schemes:
  - DoT
  - DoH
  - possibly DoQ
  - possibly DNSCrypt
- some mobile/Apple devices react differently when encrypted DNS is absent or
  blocked
- we should support privacy-forward configurations without forcing them on
  networks that do not want the complexity

## Tasks

- design an option surface for encrypted DNS client access
- decide which schemes are v1 and which are optional follow-ons:
  - DoT should be considered baseline
  - DoH should be considered baseline
  - DoQ and DNSCrypt should be evaluated as optional extras
- decide whether the primary backend should be:
  - Technitium capabilities already present in the stack
  - a separate TLS front-end/reverse proxy
  - or a provider-specific backend module
- expose the feature as opt-in, not default-on
- document expected ports, certificates, and LAN-client discovery model
- decide whether to support discovery/advertisement mechanisms such as DDR
  instead of requiring every client to be configured manually
- ensure the feature composes with the existing plain-DNS service instead of
  replacing it abruptly

## Constraints

- do not require encrypted DNS for the base router role
- do not silently intercept or rewrite client DNS as part of this item
- validate on `router-backup` first

## Validation

- disabled by default => existing router behavior unchanged
- enabled => clients can successfully query the configured encrypted resolver
- enabled with multiple schemes => flake users can choose the subset they want
- router still serves plain DNS for clients that do not opt in

