# Migration from sops-nix to agenix

## Why Migrate?

- **Simpler key management**: Use existing SSH keys instead of managing separate age keys
- **Single location**: No more age keys in `/etc/nixos/secrets/age-key.txt` AND `~/.config/sops/age/keys.txt`
- **Better integration**: SSH host keys are automatically managed by NixOS
- **Standard practice**: agenix is the more common approach in NixOS community

## Current State

### sops-nix setup:
- System secrets: `/var/lib/sops/age/keys.txt` or `/etc/nixos/secrets/age-key.txt`
- User secrets: `~/.config/sops/age/keys.txt`
- Hosts using sops: gateway, workstation, homeserver, attic-cache, rustdesk, inference-vm

### Existing SSH keys:
- **Workstation host:** `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFAzJUqDpasPy2B+vODDAZOdGJ/7DiZ1wWjbWkM1Bi8`
- **Gateway host:** `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGjM16WJ9SUCs+moDo8QTTbbEJMd0EYZPGItC6oV4WiO`
- **User (deepwatrcreatur):** `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIB4ELcnxIV0zujIJ4EPubU5nkKPV7G8pZ3tDDjZ6pXI`

## Migration Strategy

### Phase 1: Preparation (No disruption)

1. **Add agenix to flake inputs:**
   ```nix
   inputs.agenix = {
     url = "github:ryantm/agenix";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   ```

2. **Collect all SSH host keys:**
   ```bash
   # For each NixOS host:
   ssh HOST "cat /etc/ssh/ssh_host_ed25519_key.pub" > ssh-keys/HOST-host-ed25519.pub
   ```

3. **Create `secrets.nix`** (agenix equivalent of `.sops.yaml`):
   ```nix
   # secrets.nix
   let
     # System host keys
     gateway = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGjM16WJ9SUCs+moDo8QTTbbEJMd0EYZPGItC6oV4WiO";
     workstation = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFAzJUqDpasPy2B+vODDAZOdGJ/7DiZ1wWjbWkM1Bi8";
     homeserver = "ssh-ed25519 AAAAC3..."; # Get from homeserver
     
     # User keys
     deepwatrcreatur = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIB4ELcnxIV0zujIJ4EPubU5nkKPV7G8pZ3tDDjZ6pXI";
     
     # Convenience groups
     allHosts = [ gateway workstation homeserver ];
     allUsers = [ deepwatrcreatur ];
     allKeys = allHosts ++ allUsers;
   in
   {
     # System-level secrets (accessible by root)
     "cloudflare-api-key.age".publicKeys = [ gateway homeserver ] ++ allUsers;
     "technitium-api-key.age".publicKeys = [ gateway workstation ] ++ allUsers;
     
     # User-level secrets (accessible by user)
     "github-token.age".publicKeys = allKeys;
     "grok-api-key.age".publicKeys = allKeys;
   }
   ```

4. **Install the correct agenix CLI locally:**
   ```bash
   # Use the ryantm/agenix tool that works with repo-root secrets.nix.
   # Do not assume any package named `agenix` in PATH is correct.
   ```

   Compatibility note:

   - On `workstation`, the default `agenix` in `PATH` was `agenix-cli 0.1.2`
   - That tool expects `.agenix.toml` and is incompatible with this repo's
     `secrets.nix`-based workflow
   - If `agenix --help` or runtime errors mention `.agenix.toml`, do not use it
     for this repo

### Phase 2: Parallel Operation (Test without breaking existing)

5. **Add agenix modules alongside sops:**
   ```nix
   # In host config
   imports = [
     inputs.agenix.nixosModules.default
     # Keep existing sops imports
   ];
   
   # Configure both
   age.secrets.test-secret = {
     file = ../../secrets/test-secret.age;
     owner = "root";
     group = "root";
   };
   # sops config stays unchanged
   ```

6. **Create new secrets with agenix:**
   ```bash
   cd secrets/
   agenix -e test-secret.age  # Creates and encrypts with keys from secrets.nix
   ```

7. **Test on non-critical host** (e.g., test VM or workstation)

### Phase 3: Incremental Migration

8. **Migrate secrets one at a time:**
   - Decrypt with sops: `sops -d old-secret.enc > plaintext`
   - Encrypt with agenix: `agenix -e new-secret.age < plaintext`
   - Update module to use agenix secret path
   - Test, then move to next secret

9. **Host-by-host migration order:**
   - Start with: **workstation** (easiest to recover)
   - Then: **gateway** (core infrastructure, test thoroughly)
   - Then: **homeserver** (many secrets, do carefully)
   - Finally: **LXC containers** (attic-cache, rustdesk, etc.)

### Phase 4: Cleanup

10. **Remove sops-nix:**
    - Remove from flake inputs
    - Delete sops module imports
    - Remove age key files
    - Archive old encrypted secrets

## Key Differences: sops-nix vs agenix

| Feature | sops-nix | agenix |
|---------|----------|--------|
| Keys | Separate age keys | SSH host/user keys |
| File format | JSON/YAML/binary + metadata | Age-encrypted binary |
| Editing | `sops file.enc` | `agenix -e file.age` |
| Config | `.sops.yaml` per directory | Single `secrets.nix` at root |
| Rekeying | `sops updatekeys` | `agenix -r` with the correct `ryantm/agenix` CLI |
| Home-manager | Built-in support | Separate HM module |

## SSH Keys Requirements

**Yes, you need both:**
- **Host SSH key** (per system): `/etc/ssh/ssh_host_ed25519_key.pub` - for system-level secrets
- **User SSH key** (per user): `~/.ssh/id_ed25519.pub` - for user-level secrets in home-manager

**NixOS generates host keys automatically** on first boot, so you just need to collect them.

## Recommended Approach

Given your current working setup, **consider staying with sops-nix** but consolidating:
- Keep one age key per host in `/etc/nixos/secrets/age-key.txt`
- For user secrets, derive from system key or use a single user age key
- The "two places" issue can be solved without full migration

**If you do migrate to agenix:**
- Budget 2-4 hours for careful migration
- Test each host thoroughly
- Keep backups of encrypted secrets
- Don't rush - parallel operation allows safe transition

## Next Steps

1. Decide: Full agenix migration vs. sops consolidation?
2. If migrating: Start with workstation (low-risk test)
3. If consolidating: Update sops configs to use consistent key paths

Would you like me to:
- A) Create the agenix migration implementation (secrets.nix + module changes)
- B) Consolidate existing sops setup to use single key location
- C) Keep current setup (it works, just minor inconvenience)
