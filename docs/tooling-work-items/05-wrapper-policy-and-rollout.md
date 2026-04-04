# 05 Wrapper Policy And Rollout

Status: `ready`

Suggested branch: `docs/tooling-wrapper-policy`

## Goal

Write down a repo-wide policy for when commands should be wrapped with `fnox`
and align the existing implementation with that policy where low-risk cleanup is
needed.

## Scope

- document the rule that commands should be wrapped only when they regularly
  need secrets or stable policy defaults
- explicitly document which command categories should stay unwrapped
- note the canonical-name preference and fallback pattern already used in this
  repo
- leave concise follow-up notes if the current implementation deviates from the
  policy in ways that should be fixed later

## Validation

- README or queue docs make the wrapping rule easy to discover
- the policy is specific enough that a future agent can decide whether a new
  wrapper belongs in scope without reopening the whole debate
