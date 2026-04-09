# Procedure: Agenix Secret Migration

**Context**: Promoting local secrets to repo-wide management or migrating between
different encryption keys.

## Steps

1. **Verify Source**: Identify the existing secret (e.g. in `~/.env` or manual).
2. **Add to secrets.nix**:
   ```nix
   "new-secret.age".publicKeys = [ userKey hostKey ];
   ```
3. **Edit with agenix**:
   ```bash
   EDITOR=nvim agenix -e new-secret.age
   ```
4. **Reference in Module**:
   ```nix
   age.secrets.new-secret = {
     file = ../../secrets-agenix/new-secret.age;
     owner = "service-user";
   };
   ```
5. **Validation**: Rebuild and check `/run/agenix/new-secret`.

## Multi-Host Migration

- If migrating a secret across multiple hosts, ensure all target host keys are in `secrets.nix`.
- Use the `helpers/optional-secrets.nix` pattern if some hosts may not have the secret yet.
