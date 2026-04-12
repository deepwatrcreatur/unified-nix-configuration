# Tooling Agent Prompts

Use these prompts to dispatch other agents onto the tooling queue.

## Prompt 1

Read [`docs/tooling-work-items/START-HERE.md`](./START-HERE.md) and take the
highest-priority item still marked `Status: \`ready\``. Focus only on that one
item, keep the work to one PR, and update the item status in your branch.

## Prompt 24

Work on [`24-gh-fnox-wrapper-completion.md`](./24-gh-fnox-wrapper-completion.md).

Create a branch named `fix/tooling-gh-fnox-wrapper`.

Task:
- finish the repo-managed credential path for `gh`
- make the canonical `gh` command work for agent PR workflows without relying
  on a fragile ambient `GH_TOKEN`

Important constraints:
- do not redesign every secret path in the repo
- keep a clear raw/bypass path for debugging
- optimize for restoring `gh pr view`, `gh pr checks`, and merge flows first

Deliver:
- branch commit(s)
- short note describing how `gh` is now sourced and how to bypass it

## Prompt 25

Work on [`25-agent-build-cache-fallback-and-trust.md`](./25-agent-build-cache-fallback-and-trust.md).

Create a branch named `fix/tooling-agent-build-cache-fallback`.

Task:
- make agent builds behave predictably when `attic-cache` is unavailable or
  when optional public caches are not trusted
- document the intended degraded-mode build path

Important constraints:
- do not solve the router DHCP outage in this task
- prefer a clear first-class cache policy over ad hoc one-off flags
- keep the result practical for agents running builds from this repo

Deliver:
- branch commit(s)
- concise summary of cache trust/fallback behavior
