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

## Prompt 5

Implement [`06-sops-compatibility-layer-cleanup.md`](./06-sops-compatibility-layer-cleanup.md).
Audit the remaining SOPS-era references and fallback logic, remove or clearly
mark the stale ones, and keep only the compatibility paths that are still
actually needed for agenix-first hosts.

## Prompt 6

Implement [`07-agenix-helper-flake-evaluation.md`](./07-agenix-helper-flake-evaluation.md).
Assess whether the repo’s agenix helper patterns are mature enough for
extraction into a reusable flake, and leave a concrete recommendation with a
minimal proposed surface if extraction is justified.

## Prompt 7

Implement [`08-agenix-migration-layer-stabilization.md`](./08-agenix-migration-layer-stabilization.md).
Tighten the repo’s agenix migration layer so the active agenix-first behavior
is easier to distinguish from temporary compatibility logic.

## Prompt 8

Implement [`09-agenix-helper-flake-threshold.md`](./09-agenix-helper-flake-threshold.md).
Define a concrete threshold for when the repo’s agenix helper patterns should
stay local versus be extracted into a reusable flake.

## Prompt 9

Implement [`10-den-legacy-inventory-reduction.md`](./10-den-legacy-inventory-reduction.md).
Audit the remaining non-router `mode = "legacy"` inventory entries and make it
clear which ones are intentional, blocked, or ready for den-native cleanup.

## Prompt 10

Implement [`11-host-metadata-source-of-truth.md`](./11-host-metadata-source-of-truth.md).
Clarify the split between `den/inventory` and `lib/hosts.nix`, and reduce one
real drift-prone edge if you can do so without destabilizing outputs.

## Prompt 11

Implement [`12-retire-home-manager-sops-secrets-activation.md`](./12-retire-home-manager-sops-secrets-activation.md).
Figure out whether `modules/home-manager/secrets-activation.nix` should be
retired or explicitly fenced as temporary compatibility, then make the import
story clearer for future agents.
