# 23 Cross-Agent Memory Extraction Pipeline

Status: `ready`

Suggested branch: `feat/tooling-memory-extraction`

## Goal

Build a pipeline to extract "learned knowledge" from Claude Code
(`history.jsonl`), Gemini, and Codex logs, and archive them into a
repo-local, searchable format.

## Why

Each agent session generates a wealth of "discovered truth" (e.g., "this
specific kernel module is needed for the P40 on NixOS 25.11"). Right now,
that truth is buried in `~/.claude/history.jsonl` or session logs.
This task is about building the "extractor" that pulls these nuggets out
and places them into the Repo Memory Archive (linking with CASS/CM/Mem0).

## Scope

- write a parser for `~/.claude/history.jsonl` to extract technical findings
- write similar extractors for Gemini/Codex if logs are accessible
- implement a "Deduplication" and "Refinement" step (possibly agent-assisted)
- output the findings into a structured repo archive (e.g., `docs/memory/`)
- ensure the archive is indexed by CASS/CM for future retrieval

## Non-Goals

- real-time memory syncing (batch extraction is fine for now)
- archiving sensitive credentials (must be filtered out)

## Validation

- running the extraction script populates `docs/memory/` with valid findings
- the findings are searchable via existing tools
- docs explain the retention and refinement policy for the archive
