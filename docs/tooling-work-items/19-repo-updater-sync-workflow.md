# 19 Repo Updater Sync Workflow

Status: `ready`

Suggested branch: `feat/tooling-repo-updater`

## Goal

Adopt `repo_updater` (RU) to manage the collection of ~20 flake repositories
under `~/flakes/`, ensuring they stay in sync and have consistent PR review
coverage.

## Why

The `~/flakes/` directory contains dozens of interconnected repos (proxmox,
router, rtk, agenix, etc.). Manually pulling, checking status, and managing
PRs across all of them is a bottleneck for both human and agent operators.
`ru sync` provides a parallelized sync, and `ru review` allows agents to
systematically process open PRs across the fleet.

## Scope

- install or package `repo_updater` for this environment
- configure the workspace root (`~/flakes/`) for RU
- document common workflows:
  - `ru sync` for fleet-wide updates
  - `ru status` for identifying uncommitted changes across repos
  - `ru review` for agentic PR triaging
- identify any "protected" repos that should be excluded from mass updates

## Non-Goals

- replacing the core `nix flake update` workflow
- automated force-pushing or bulk merging without human/CI validation

## Validation

- `ru sync` successfully pulls updates for all repositories in `~/flakes/`
- `ru status` provides a clear overview of the fleet's state
- docs make it obvious how agents should use RU to keep the fleet healthy
