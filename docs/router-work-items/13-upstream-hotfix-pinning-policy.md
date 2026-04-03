# Upstream Hotfix Pinning Policy

Status: `ready`
Suggested branch: `docs/router-hotfix-pinning-policy`
Priority: `medium`

## Goal

Document and standardize how this repo temporarily consumes upstream hotfixes
for critical router paths, then returns to stable upstream refs.

## Why This Matters

The Technitium NTP sync fix required a short-lived upstream hotfix branch and a
fast follow-up to repoint the input back to upstream `main`. That worked, but
the process is currently implicit and easy to repeat inconsistently.

## Tasks

- write a short policy for temporary upstream hotfix consumption
- specify what must appear in the PR description or commit message:
  - reason for the ref move
  - expected lockfile churn
  - validation commands
  - rollback path
- clarify when to use:
  - upstream branch
  - immutable commit pin
  - upstream `main` after merge

## Deliverable

- a concise policy note in docs
- if appropriate, a short PR template/checklist snippet

## Do Not

- do not redesign the whole flake input strategy
- do not treat all inputs as equally critical; focus on router/infra hotfixes
