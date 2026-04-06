# Tooling Agent Prompts

Use these prompts to dispatch other agents onto the tooling queue.

## Prompt 1

Read [`docs/tooling-work-items/START-HERE.md`](./START-HERE.md) and take the
highest-priority item still marked `Status: \`ready\``. Focus only on that one
item, keep the work to one PR, and update the item status in your branch.

## Prompt 2

Implement [`10-remove-gstack-and-browse-coupling.md`](./10-remove-gstack-and-browse-coupling.md).
Remove repo-local `gstack` assumptions and replace them with agent guidance that
does not depend on a Claude-only browsing workflow.
