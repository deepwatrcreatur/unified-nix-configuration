# Host Migration Work Items

Start here if you are picking up or assigning work:

- [`START-HERE.md`](./START-HERE.md)
- [`../host-naming-and-dendritic-role-migration-plan.md`](../host-naming-and-dendritic-role-migration-plan.md)

This directory is the active backlog for decoupling machine names from functional roles (migrating to gemstone names like `emerald`, `sapphire`, `ruby`, `garnet` alongside `phoenix`) and delegating roles to `den/aspects/` with DNS/SSH aliases.

## Current Ranked Queue

1. [01 Decouple Hostname Role Checks](./01-decouple-hostname-role-checks.md) — `in-progress` (Foundational)
2. [02 Attic Cache To Emerald Migration](./02-attic-cache-to-emerald-migration.md) — `ready` (Blocked by 01)
3. [03 Homeserver To Sapphire Migration](./03-homeserver-to-sapphire-migration.md) — `ready` (Blocked by 01)
4. [04 Router Role Boundary And Ruby Cutover](./04-router-role-boundary-and-ruby-cutover.md) — `ready` (Blocked by 01, 02)
5. [05 Decouple Podman Container Stacks into Atomic Aspects](./05-decouple-podman-container-stacks-into-atomic-aspects.md) — `ready`
6. [06 Remote Builder Capability Options](./06-remote-builder-capability-options.md) — `ready`
