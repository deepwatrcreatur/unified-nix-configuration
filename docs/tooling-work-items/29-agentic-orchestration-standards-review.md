# 29 Agentic Orchestration Standards Review

Status: `open`
Suggested branch: `docs/agentic-orchestration-standards-review`
Priority: `low`

## Goal

Review, refine, and validate the Agentic Orchestration Standards that were
established at `standards/agentic-orchestration/` in the workspace root during
the 2026-04-23 Kea/VRRP regression incident.

## Background

The standards directory was created to capture the multi-agent coordination
model that emerged organically during that incident. It defines a Blackboard
Architecture (shared filesystem state), ICS-based agent roles, an
observe-before-change SOP, and templates for incident summaries and ADRs.

The content was written under incident pressure and has not been reviewed by a
human operator or a second agent session. It may contain inaccuracies, gaps, or
decisions that felt right at the time but do not hold up on reflection.

**Location:** `/home/deepwatrcreatur/flakes/standards/agentic-orchestration/`

## Files to Review

| File | What to Look For |
|---|---|
| `README.md` | Is the bootstrap sequence correct? Does it match actual incident workflow? |
| `MODEL.md` | Are the agent roles realistic for a 1–2 person homelab? Is the RESEARCH_LEDGER format burdensome? |
| `SOP_FORENSIC_ENGINEERING.md` | Are the Phase 2 tool commands correct? Is Phase 0 actually done in practice? |
| `TEMPLATES/INCIDENT_SUMMARY.md` | Try filling it out for the 2026-04-23 incident. Does it fit? |
| `TEMPLATES/ADR.md` | Does the "What Was Tried and Failed" table capture the right things? |
| `ATTRIBUTION.md` | Are the attribution notes accurate? Any missing sources? |

## Specific Questions for the Reviewer

1. **Scope creep:** The SOP assumes NixOS/Linux networking context (generations,
   `nixos-rebuild`, `nftables`). Should there be a general-purpose SOP and a
   NixOS-specific extension, or is the current mix appropriate given where the
   standards live?

2. **RESEARCH_LEDGER format:** The entry format requires a Goal, Command, Result,
   and Interpretation field for every probe. Is this too heavy for quick
   exploratory commands, or is the discipline worth the overhead?

3. **Template fit against the real incident:** The 2026-04-23 incident ran
   across multiple agent sessions with rotating roles. Does the INCIDENT_SUMMARY
   template cover the information that actually mattered, or does it miss
   anything significant?

4. **Agent-prompt integration:** Should the `agent-guides/START-HERE.md` in the
   nix-config repo reference these standards, or should the standards be
   imported into the agent-guides repo directly?

## Tasks

- [ ] Human review pass on all five files above
- [ ] Answer the four specific questions above in a brief review note
- [ ] Update any files that need correction
- [ ] Optionally: back-fill the 2026-04-23 incident's existing SUMMARY.md and
  RESEARCH_LEDGER.md to conform to the template format, as a validation exercise
- [ ] Optionally: add a pointer to these standards from `agent-guides/START-HERE.md`

## Validation

The standards are good enough when:
- A new agent session handed only the README can bootstrap and contribute to an
  incident without any verbal explanation
- The INCIDENT_SUMMARY template can be filled out for 2026-04-23 in under 10 minutes
- No critical information from the real incident is missing from the template fields
