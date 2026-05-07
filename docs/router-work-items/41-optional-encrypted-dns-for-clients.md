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

## Investigation Notes

- live `router` currently exposes:
  - plain DNS on `10.10.10.1:53`
  - no listener on `:853`
  - `:443` owned by Caddy, not Technitium
- `services.router-technitium.listenEndPoints` already exists and can
  declaratively synchronize Technitium listener addresses via its HTTP API
- Technitium's current official docs/product pages explicitly describe native
  support for:
  - DNS-over-TLS (DoT)
  - DNS-over-HTTPS (DoH)
  - DNS-over-QUIC (DoQ)
- there is no corresponding evidence in the current stack that DNSCrypt is an
  existing first-class fit, so it should be treated as deferred unless a real
  user need appears

Recommended starting architecture:

- baseline v1 protocols:
  - DoT
  - DoH
- optional later protocol:
  - DoQ
- deferred:
  - DNSCrypt

The main deployment constraint is port ownership:

- Caddy already owns `:443`
- DoT needs raw `:853`
- DoQ needs raw QUIC/UDP listener ownership

So this item should assume one of two designs:

1. Technitium hosts encrypted DNS directly and receives certificate material
   declaratively
2. Caddy terminates only the DoH HTTPS surface while Technitium continues to
   own DoT/DoQ directly

The first design is simpler if the certificate story is clean. The second is
only justified if we want to reuse existing ACME/Caddy automation for DoH.

## Tasks

- design an option surface for encrypted DNS client access
- decide which schemes are v1 and which are optional follow-ons:
  - DoT should be considered baseline
  - DoH should be considered baseline
  - DoQ should be evaluated as an optional extra
  - DNSCrypt should default to deferred
- decide whether the primary backend should be:
  - Technitium native encrypted-DNS capabilities
  - Caddy only for DoH termination
  - or a separate TLS front-end/reverse proxy if certificate reuse forces it
- expose the feature as opt-in, not default-on
- document expected ports, certificates, and LAN-client discovery model
- decide whether to support discovery/advertisement mechanisms such as DDR
  instead of requiring every client to be configured manually
- ensure the feature composes with the existing plain-DNS service instead of
  replacing it abruptly
- document hostname strategy, e.g. a dedicated resolver name such as
  `dns.<domain>` rather than reusing the admin UI hostnames

## Constraints

- do not require encrypted DNS for the base router role
- do not silently intercept or rewrite client DNS as part of this item
- validate on `router-backup` first

## Validation

- disabled by default => existing router behavior unchanged
- enabled => clients can successfully query the configured encrypted resolver
- enabled with multiple schemes => flake users can choose the subset they want
- router still serves plain DNS for clients that do not opt in
