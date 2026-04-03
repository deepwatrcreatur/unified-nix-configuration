# Tooling Agent Prompts

Use these prompts to dispatch other agents onto the tooling queue.

## Prompt 1

Read [`docs/tooling-work-items/START-HERE.md`](./START-HERE.md) and take the
highest-priority item still marked `Status: \`ready\``. Focus only on that one
item, keep the work to one PR, and update the item status in your branch.

## Prompt 2

Implement [`01-agent-cli-fnox-wrappers.md`](./01-agent-cli-fnox-wrappers.md).
Audit the existing `fnox` wiring, add wrappers only for the agent CLIs that
actually benefit from secret injection, preserve raw commands where needed, and
follow the existing `gh`/`bw` fallback style. Validate the resulting aliases or
package selection paths before opening a PR.

## Prompt 3

Implement [`02-api-and-proxmox-wrapper-candidates.md`](./02-api-and-proxmox-wrapper-candidates.md).
Decide whether this repo should expose a dedicated API helper wrapper and any
Proxmox-specific helper wrappers. Do not wrap generic build tools. Leave behind
clear docs or follow-up notes for anything intentionally deferred.

## Prompt 4

Implement [`03-wrapper-policy-and-rollout.md`](./03-wrapper-policy-and-rollout.md).
Document and encode a repo-wide policy for when commands should or should not
be wrapped with `fnox`, and make sure the rollout path stays reviewable and
predictable across hosts.
