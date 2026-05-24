# Discussion 01: Should Any Hosts Start Using Hickory DNS?

**Status:** closed
**Scope:** `unified-nix-configuration`
**Date:** 2026-05-23

## Why this discussion exists

The repo currently has no Hickory references, while router DNS is explicitly
anchored around Technitium:

- `hosts/nixos/router/service-capability.nix` sets
  `services.router-dns-service.provider = "technitium"`
- `hosts/nixos/router/role.nix` contains Technitium-specific RFC2136, secrets,
  dashboard, and monitoring wiring
- `docs/router-source-of-truth.md` and `docs/kea-technitium-architecture.md`
  describe a Technitium-centered DNS authority model

Because recent HA work has deliberately avoided casual DNS ownership changes,
this discussion asked whether Hickory should enter the repo at all, and if so,
where.

## Participation record

This was a **real four-seat round** with substantive responses from:

- Codex CLI
- Gemini CLI
- DeepSeek API
- OpenCode free-model enrichment seat

An additional Claude CLI follow-up was attempted during archival but did not
produce usable text in time, so it is not counted in the synthesis below.

## Voice summaries

### Codex CLI

- Strongest on the claim that Hickory's best fit here would be a **bounded
  declarative experiment**, not a production router DNS replacement.
- The least-bad candidate was `router-backup`, but only as a management-only or
  loopback sidecar for zone-generation or resolver experiments.
- Emphasized that the current repo does **not** have a real Hickory role:
  no module, no ownership model, no docs, and no HA boundary for DNS service
  itself.
- Bottom line: do not start using Hickory now; at most run a clearly-labeled
  experiment on the spare router if a future declarative DNS path needs study.

### Gemini CLI

- Strongest on the risk that introducing Hickory now would **fragment an active
  migration**: the repo is already converging on Kea + Technitium rather than
  redesigning DNS authority.
- Framed Hickory's best argument as memory safety and declarative purity, but
  still judged that benefit too small relative to current migration churn.
- Nominated lightweight non-router environments as the only plausible testing
  surface, but not as something the repo currently needs.
- Bottom line: no host should adopt Hickory now.

### DeepSeek API

- Strongest on the argument that Hickory could make sense on a **non-router,
  non-production resolver host** if the goal were a lightweight Rust recursive
  resolver with DNSSEC benefits.
- But it judged the current repo unprepared for that because DNS is operationally
  unified around the router's Technitium authority model.
- Emphasized that the repo currently lacks both an explicit non-router DNS lab
  host and a compelling Hickory-driven use case.
- Bottom line: no host currently justifies the split or configuration overhead.

### OpenCode free-model enrichment seat

- Strongest on the argument that Hickory would slightly improve the repo only if
  the goal were broader tooling diversity or safe workstation-scale experiments.
- Picked `workstation` as the least risky candidate for isolated local DNS
  experimentation, but still judged the payoff too small.
- Emphasized that production router DNS is too deeply coupled to Technitium's
  HA-sensitive features to justify a new stack right now.
- Bottom line: slight theoretical upside, not enough to justify the churn.

## Convergence

The round converged on four points.

1. **Do not introduce Hickory into the production router DNS path now.**
   All seats agreed the current router DNS model is too Technitium-specific and
   too entangled with Kea DDNS, RFC2136, secrets, dashboarding, and HA caution
   to justify a second DNS authority story.

2. **If Hickory appears at all, it should start as an experiment, not a
   supported role.**
   The only plausible candidates mentioned were non-production surfaces like
   `workstation`, a lightweight lab host, or a management-only `router-backup`
   sidecar.

3. **The repo lacks the plumbing for real Hickory adoption.**
   There is no existing Hickory module, no ownership boundary for it, no docs,
   and no migration plan.

4. **The expected benefit is small relative to the churn.**
   Hickory's advantages were mostly framed as declarative purity, memory safety,
   or lighter-weight resolver behavior. None of the seats judged that strong
   enough to outweigh the operational cost today.

## Maintained line

The maintained line after this round is:

- no hosts should start **using Hickory DNS as a supported role now**
- the router DNS stack should stay centered on the current Kea + Technitium
  model while HA and ownership boundaries remain active concerns
- if Hickory ever enters this repo, it should do so as a clearly isolated
  experiment rather than an ambient alternative

## Bottom line

There is **not** currently a strong enough case to start using Hickory DNS on
any host in `unified-nix-configuration`.

The strongest possible next step, if interest remains, would be a narrowly
labeled experiment on a non-production host or management-only sidecar rather
than a router or fleet-wide adoption.
