# Upstream Hotfix Pinning Policy

This policy standardizes how `unified-nix-configuration` consumes temporary upstream hotfixes for critical router and infrastructure paths.

## Principles

1. **Safety First**: Hotfixes are for critical bugs only (security, boot failure, major network disruption).
2. **Short Lifecycle**: Hotfix pins must be temporary. Repoint to stable upstream `main` as soon as the fix is merged.
3. **Traceability**: Every hotfix pin must document its origin and purpose.

## Lifecycle of a Hotfix

### 1. Identifying the Need
A bug is found in an upstream dependency (e.g., `nix-router-optimized`) that blocks local operations.

### 2. Pinned Consumption
Update `flake.nix` to point to the specific branch or commit containing the fix.

**Acceptable Refs:**
- `branch`: Use for fast-moving fixes where multiple iterations are expected.
- `commit`: Use for immutable pins when the fix is final but not yet merged to `main`.

### 3. Documentation Requirements
The PR description or commit message MUST include:
- **Reason**: Link to the issue or describe the critical failure.
- **Ref Move**: Explicitly state which input moved and why (e.g., `github:user/repo/branch-name`).
- **Validation**: Commands used to prove the hotfix works (e.g., `nix build .#nixosConfigurations.router...`).
- **Rollback Path**: Note that the ref should be moved back to `main` once merged.

### 4. Returning to Stable
Once the upstream PR is merged to `main`:
1. Update `flake.nix` back to `github:user/repo/main`.
2. Run `nix flake update <input-name>`.
3. Verify the system still builds and functions correctly.

## PR Checklist Snippet

Add this to PRs involving upstream hotfixes:

```markdown
### Upstream Hotfix Checklist
- [ ] Input affected: `...`
- [ ] Temporary ref: `...`
- [ ] Link to upstream PR/issue: `...`
- [ ] Validation command: `nix build ...`
- [ ] Follow-up task created to revert to `main`
```

## When to Avoid Hotfixes
- Non-critical feature requests.
- Aesthetic or documentation-only upstream changes.
- Experimental features that can be tested in a local branch first.
