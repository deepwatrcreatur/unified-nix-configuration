# 32 Public Repo Stress Analysis Demo

Status: `ready`
Suggested branch: `feat/public-repo-stress-analysis-demo`
Priority: `high`

## Goal

Build a working demo that imports a small set of large public repositories and
computes branch/history stress views using the project's information-theoretic
and active-inference framing.

## Why

- The user wants more than notes about lines added and deleted.
- The point of the demo is to show branch stress, change heat over time, and
  code-history pressure signals that can be discussed as a live artifact.
- This is the most directly user-visible differentiator once a Forgejo-shell
  demo surface exists.

## Scope

1. Choose a small initial corpus of large public repos to import.
2. Define the first demo metrics clearly enough to implement and compare:
   - branch stress
   - change-history heat
   - at least one active-inference-aligned score or visualization
3. Build the import + analysis pipeline needed to produce those artifacts.
4. Expose the output in a way the Forgejo-shell surface can consume, even if
   the first version is read-only.

## Non-Goals

- Perfect theoretical completeness in the first pass
- Supporting arbitrary private repos
- Replacing Forgejo UI wholesale

## Validation

- at least a few public repos can be imported reproducibly
- the demo emits outputs richer than added/deleted LOC counts
- the resulting artifacts can be shown as branch/history heat or stress views
- the metric definitions are written down well enough that another agent can
  extend them without reverse-engineering the first implementation

## Notes

Prefer a narrow but honest first demo over a broad pseudo-platform. A small
number of compelling repo examples is enough for the initial pass.
