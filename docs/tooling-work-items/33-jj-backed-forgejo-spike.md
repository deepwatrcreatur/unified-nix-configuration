# 33 JJ-Backed Forgejo Spike

Status: `ready`
Suggested branch: `spike/jj-backed-forgejo`
Priority: `medium`

## Goal

Prove a credible path for running a Forgejo fork with `jj` underneath or
adjacent to its repository/change model, as groundwork for the
Forgejo-shell-based analysis environment.

## Why

- The user explicitly wants `jj` involved under the hood of the Forgejo fork.
- That is likely deeper than ordinary deployment plumbing and should be
  treated as a spike first, not hidden inside a generic demo task.
- A bounded spike can answer whether the right shape is:
  - direct Forgejo fork changes,
  - a sidecar/indexer approach, or
  - a mirrored JJ-native analysis path behind a Forgejo-facing UI.

## Scope

1. Audit the minimal integration points between Forgejo semantics and JJ
   semantics that matter for this repo’s intended demo.
2. Identify whether a true Forgejo fork is required for the first demo.
3. Produce a recommendation with one implementation path that is small enough
   for a follow-up PR-sized item.
4. If a low-risk prototype is possible, demonstrate one narrow JJ-backed flow.

## Non-Goals

- Shipping a complete production Forgejo fork in one item
- Solving every Forgejo/JJ mismatch
- Rewriting the demo surface before the architecture is understood

## Validation

- there is a written recommendation for the first viable JJ integration path
- the recommendation distinguishes spike findings from long-term aspirations
- if a prototype lands, it is narrow, reproducible, and clearly described

## Notes

This item should reduce architecture uncertainty, not multiply it. Prefer one
strong recommendation over a catalog of possibilities.
