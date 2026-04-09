# CASS Memory (CM) Guide for Agents

This repo uses a procedural memory layer (Playbook) to capture recurring
workflows and technical discoveries.

## Retrieval

Before starting a complex task, check if a procedure already exists:
```bash
grep -r "Task Name" docs/playbook/
```
If Task 15 (CASS) is enabled, use `qs` to search raw history:
```bash
qs "Technitium DHCP rename"
```

## Contribution (The Pipeline)

When you discover a stable solution to a recurring problem:
1. **Reflect**: Extract the core steps from your session history.
2. **Draft**: Create or update a file in `docs/playbook/`.
3. **Curate**: Commit the change as part of your PR.

## Playbook vs. Docs

- **Docs**: High-level architecture, design rationale, permanent configuration.
- **Playbook**: Low-level "how-to", troubleshooting commands, transient workarounds.
