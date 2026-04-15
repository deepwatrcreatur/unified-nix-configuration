# 21 Fleet Integration Flake Design

Status: `done`

Suggested branch: `feat/tooling-fleet-integration`

## Goal

Design and implement a dedicated "Integration Flake" (or Meta-Flake) that
aggregates all experimental `nix-*` tool repositories into a single
consumable interface.

## Why

The `unified-nix-configuration` flake is becoming a "Mega-Flake" with dozens of
inputs (30+ and growing). This makes `flake.lock` management painful and
increases the risk of evaluation slowdowns. Many of the newer repos (like
`nix-command-guard`, `nix-session-search`, `nix-rtk`) are logically part of
a "coding-agent fleet" but are currently managed as top-level inputs to the
main system config.

An Integration Flake would:
- centralize versions of all experimental tools
- provide a unified overlay (`inputs.fleet.overlays.default`)
- provide a unified set of modules (`inputs.fleet.homeModules.agent-stack`)
- simplify `unified-nix-configuration` by reducing its input surface

## Scope

- determine whether to repurpose `nix-repo-fleet` or create a new repo
- draft the `flake.nix` structure for the integration layer:
  - inputs: all `nix-*` tool flakes
  - outputs: unified overlays, packages, and modules
- define a "stable" versus "experimental" promotion path for tools
- document how `unified-nix-configuration` should consume the fleet flake

## Non-Goals

- merging the code of all tool repos into one (keeping them as separate flakes
  is good for isolation)
- migrating every single input in one PR

## Validation

- a prototype integration flake evaluates cleanly
- `unified-nix-configuration` can replace 3-5 individual inputs with a single
  `fleet` input and still function
- docs explain the benefit of the integration layer to future agents

## Assessment Notes

Current independent assessment: **probably yes eventually, but not as the first
move**.

Why:

- the sibling flakes currently sitting beside this repo
  (`unified-nix-configuration-service-deps`,
  `unified-nix-configuration-agenix-helper-eval`,
  `unified-nix-configuration-fnox`) still look like broad near-forks of the
  main flake rather than thin, purpose-built extractions
- their `flake.nix` files still carry essentially the full top-level input set,
  so a new integration flake on top would risk adding another layer without
  actually removing the current duplication
- in other words, the immediate problem is not only "too many inputs in one
  repo"; it is also "several repos still duplicate the same giant base"

This suggests a sequencing rule:

1. first make the split flakes genuinely narrow
2. then introduce an integration flake only if it materially reduces top-level
   inputs in `unified-nix-configuration`

## Recommended Direction

If this work proceeds, prefer an **agent-tooling fleet flake**, not a
catch-all "every nix repo I own" aggregator.

Good candidates:

- `nix-rtk`
- `fnox-flake`
- future session-search / command-guard / beads-related flakes
- other coding-agent-specific overlays or Home Manager modules

Poor candidates for the first version:

- general infrastructure flakes unrelated to agent tooling
- router / service / desktop UI flakes
- repos that are consumed only in one narrow place and do not need promotion

The integration layer should reduce cognitive surface area for the agent stack,
not become a second mega-flake.

## Thoughts On `nix-repo-fleet`

Do **not** repurpose `nix-repo-fleet` as the integration flake.

Reason:

- `nix-repo-fleet` already has a clear identity as operational multi-repo
  review/sync tooling
- packaging and coordinating a fleet of repos is a different concern from
  exporting a unified overlay/module interface for agent tooling
- mixing those roles would make the repo name and purpose less clear

If an integration flake is created, it should be a dedicated repo with a narrow
contract.

## Proposed Contract

The first version should be intentionally small:

- `overlays.default` for agent-tool packages
- `homeManagerModules.default` or `homeManagerModules.agent-stack`
- optionally `packages.<system>.default` for a curated agent-tool bundle
- maybe a small `lib` surface for stack composition, but avoid inventing a big
  framework

`unified-nix-configuration` should then consume that one flake for the
agent-tooling slice while leaving unrelated infra/application inputs direct.

## Pre-Conditions

Do not start implementation until at least one of these is true:

- 3-5 agent-tool-related inputs can actually be replaced by a single fleet input
- at least one sibling extracted flake has been thinned down enough to prove the
  split architecture is real rather than a cloned snapshot
- there is a clear stable/experimental promotion path for what belongs in the
  fleet flake versus direct repo consumption
