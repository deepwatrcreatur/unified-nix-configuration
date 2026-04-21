# Agent Fleet Flake Design

This document records the design and rationale for a dedicated
`nix-agent-fleet` integration flake that consolidates the agent-tooling inputs
currently scattered across `unified-nix-configuration`.

## Problem

`unified-nix-configuration` currently imports 10+ agent-tool flakes directly
as top-level inputs.  Every new tool adds to `flake.lock` size and
`nix flake update` time.  Agents that want to understand "what tools are in
the stack" must read the full 180-line `flake.nix`.

## Solution

A thin integration flake (`nix-agent-fleet`) that:
1. Takes all agent-tool inputs
2. Exports `overlays.default`, `homeManagerModules.agent-stack`
3. Is consumed by `unified-nix-configuration` as a single `nix-agent-fleet`
   input

This reduces the agent-tooling surface in `unified-nix-configuration` from
10+ inputs to 1, and gives agents a single place to inspect the stack.

## Pre-Condition Audit (met as of 2026-04-14)

| Pre-condition | Status |
|---|---|
| 3-5 agent-tool inputs can be replaced by one | ✅ 10 inputs identified |
| Promotion path defined (stable vs experimental) | ✅ see tiers below |
| At least one sibling flake thinned | Deferred — this design proceeds on input count alone |

## Tool Tiers

### Stable (in daily use, interface locked)
| Input name | Purpose |
|---|---|
| `fnox` | Credential proxy for all wrapped CLI tools |
| `nix-rtk` | RTK token-saver + Claude Code hook integration |
| `llm-agents` | Package set: claude-code, opencode, codex, etc. |
| `beads-rust` | Task graph tracker (`beads-rust` wrapper around upstream `br`) |
| `worktrunk` | Git worktree manager for parallel agent branches |

### Experimental (newer, interface may evolve)
| Input name | Purpose |
|---|---|
| `qmd` | Local document search before making changes |
| `nix-lightpanda` | Headless browser for QA/testing agents |
| `nix-markit` | Doc-to-markdown conversion |
| `agents-status-tray-hm` | Status tray Home Manager module |

## Prototype

A prototype is at `prototype/nix-agent-fleet/flake.nix`.  It is structurally
identical to the proposed production flake and can be extracted to a new repo
without modification.

To validate locally:
```bash
cd prototype/nix-agent-fleet
nix flake show
nix flake check
```

## Contract

```
inputs.nix-agent-fleet.overlays.default
inputs.nix-agent-fleet.homeManagerModules.default        # = agent-stack
inputs.nix-agent-fleet.homeManagerModules.agent-stack    # RTK + beads + pkgs
inputs.nix-agent-fleet.homeManagerModules.agent-packages # packages only
inputs.nix-agent-fleet.lib.toolTiers                     # stable/experimental lists
```

## Migration Plan for unified-nix-configuration

1. Create `github:deepwatrcreatur/nix-agent-fleet` repo (from prototype/).
2. Add as single input:
   ```nix
   nix-agent-fleet = {
     url = "github:deepwatrcreatur/nix-agent-fleet";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   ```
3. Replace in `overlays/flake-inputs.nix`:
   - `inputs.llm-agents.overlays.default` → included in fleet overlay
   - `fnox` overlay → included in fleet overlay
   - `worktrunk` overlay → included in fleet overlay
   - `nix-lightpanda.overlays.default` → included in fleet overlay
   - `nix-markit.overlays.default` → included in fleet overlay
4. Remove individual inputs: `fnox`, `worktrunk`, `qmd`, `nix-lightpanda`,
   `nix-markit`, `agents-status-tray-hm` (6 inputs).
5. Keep `llm-agents` direct if garnix cache benefit requires its specific lock.
6. Keep `nix-rtk` direct if its `llm-agents.follows` wiring matters for cache.

## Why Not nix-repo-fleet

`nix-repo-fleet` is a Python CLI for multi-repo status/triage.  Mixing it
with flake composition (overlays, modules) would confuse its identity.
The fleet flake has a different concern: exporting a Nix interface, not
running git commands.

## Inputs Explicitly Excluded

These stay as direct inputs in `unified-nix-configuration`:

- Core infra: `nixpkgs`, `home-manager`, `agenix`, `disko`, `determinate`
- Build infrastructure: `flake-utils`, `mac-app-util`, `nix-homebrew`
- Desktop/UI (non-agent): `zen-browser`, `plasma-manager`, `nix-whitesur-config`, `nix-gnome-cosmic-ui`, `zellij-vivid-rounded`
- GPU/inference: `tesla-inference-flake`
- Service infrastructure: `nix-attic-infra`, `nix-router-optimized`, `nix-authentik`, `nix-linuxbrew`, `nix-snapd`, `ssh-keys-manager`
