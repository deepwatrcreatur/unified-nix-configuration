# 20 Robot Triage Prioritization

Status: `done`

Suggested branch: `feat/tooling-robot-triage`

## Goal

Enable `beads_viewer` (bv) and its "Robot Triage" capabilities to automatically
prioritize the backlog based on PageRank and critical-path analysis.

## Why

As the `beads` graph grows, manual prioritization becomes a "best guess" effort.
`beads_viewer --robot-triage --json` provides an agent-friendly prioritization
signal that accounts for task centrality and blocking pressure. This bridges
the gap between "we have a graph" and "the agent knows exactly what to do
next."

## Scope

- install or package `beads_viewer` (bv)
- configure the `--robot-triage` output for agent consumption
- integrate the triage signal into the top-level `START-HERE.md` or
  `README.md` as the primary recommendation engine
- document how to interpret the PageRank/Critical-Path scores

## Non-Goals

- removing human agency from the final prioritization decision
- full automation of task creation/deletion

## Validation

- `bv --robot-triage` produces a valid JSON prioritization list
- the suggested tasks align with the human-perceived "next steps"
- docs explain why this tool is used over manual ranking
