# 09 Agenix Helper Flake Threshold

Status: `in-progress`

Suggested branch: `docs/tooling-agenix-helper-threshold`

## Goal

Define a concrete threshold for when this repo’s agenix helper patterns should
remain local implementation detail versus being extracted into a reusable flake.

## Why

The repo already has several agenix-adjacent patterns that look reusable:

- user-scoped agenix secret activation
- agenix-first token/config installation
- `fnox` seed-source integration
- machine-identity and bootstrap expectations

But not all repeated code should become a flake. Without an explicit threshold,
agents may try to extract too early or debate the same question repeatedly.

## Scope

- list the agenix-related patterns that are:
  - clearly repo-specific
  - potentially reusable but still unstable
  - strong candidates for eventual extraction
- define the minimum conditions for extraction, such as:
  - used across multiple repos
  - small stable interface
  - low dependence on migration compatibility
  - clear validation story
- recommend whether the current repo is above or below that threshold today

## Non-Goals

- implementing a helper flake in this PR
- generic secret-management architecture work beyond the agenix helper question
- forcing extraction because a few modules look similar

## Validation

- the recommendation is crisp enough that future agents can decide whether to
  extract or stay local without reopening the whole argument
- follow-up work can cite the threshold directly

## Notes

Bias toward staying local until the reusable surface is both clearly repeated
and operationally stable.
