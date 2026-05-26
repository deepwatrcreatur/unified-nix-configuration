# 32 Public Repo Stress Analysis Demo

Status: `done`
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

## Outcome

- The implementation already landed in the repo-managed `agent-roundtable`
  input that this flake consumes via [`flake.nix`](../../flake.nix).
- The current `/forgejo-shell` surface in
  `agent-roundtable/roundtable/lib/roundtable_web/live/forgejo_shell_live.ex`
  exposes curated public demos and links to snapshot reports.
- The import and snapshot pipeline exists in
  `agent-roundtable/roundtable/lib/roundtable/public_repo_demo.ex`:
  it resolves public refs with `git ls-remote`, samples shallow history, and
  emits JSON snapshots under `reports/public-repo-demos/`.
- Shareable report generation exists in
  `agent-roundtable/roundtable/lib/roundtable/public_repo_sna_reports.ex`,
  which renders markdown artifacts consumed alongside `/forgejo-shell/reports`.
- The current checked-in demo corpus already covers:
  - `NixOS/nixpkgs`
  - `kubernetes/kubernetes`
  - `forgejo/forgejo`
- The adjacent repo also records the upstream completion path in
  `agent-roundtable/docs/work-items/68-public-repo-investor-demo.md` and
  `agent-roundtable/docs/work-items/72-forgejo-shell-public-demo-polish.md`.

This queue item was stale in `unified-nix-configuration`; the work should be
treated as complete here rather than duplicated in a second pipeline.
