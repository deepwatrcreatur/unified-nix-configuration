# 22 Mem0 Integration for Fleet Memory

Status: `ready`

Suggested branch: `feat/tooling-mem0-integration`

## Goal

Integrate `mem0` (mem0ai) as a long-term semantic memory layer for the
entire agent fleet, focusing on "who" and "what" (facts, entities,
infrastructure topology).

## Why

Currently, agent memory is fragmented. Claude knows things Gemini doesn't,
and vice-versa. `MEMORY.md` is too manual and flat. `mem0` provides a
"smart" database that can extract facts from conversations and store them
in a queryable graph/vector format. This allows a new agent to immediately
know the infrastructure details (IPs, hostnames, user preferences) without
re-discovering them.

## Scope

- package `mem0` or provide a reproducible installation path
- initialize a local Mem0 store (SQLite/Vector-based)
- define the "Core Fact" schema (Hosts, IPs, Secrets-Policy, Shell-Prefs)
- create a "Bootstrap" script to ingest current `AGENTS.md` and `CLAUDE.md`
  into Mem0
- document the query interface for agents: `mem0 search "What is the IP of the router?"`

## Non-Goals

- storing raw session transcripts (use CASS for that)
- storing procedural "how-to" playbooks (use CM for that)

## Validation

- Mem0 correctly extracts a fact from a provided string
- a query for a stored infrastructure detail returns the correct answer
- docs explain how agents should "remember" new facts into Mem0
