# SSH Key Management Strategy

This project uses the `nix-ssh-keys-manager` flake to declaratively manage SSH `authorized_keys` and `known_hosts` across all machines while allowing for dynamic key additions.

## Current Setup

The `nix-ssh-keys-manager` flake provides a hybrid approach to SSH key management:

1. **NixOS-managed keys**: Keys are auto-populated from `.pub` files stored in the `ssh-keys/` directory. These are read-only and deployed declaratively via Nix.
2. **Dynamic keys**: Users can manually add keys dynamically to `~/.ssh/authorized_keys_dynamic` (e.g., when prompted by GitHub or other services).

### 1. NixOS Module (`authorized_keys`)

The NixOS module is imported across hosts to configure `authorized_keys` for users automatically. 

```nix
{
  imports = [ inputs.ssh-keys-manager.nixosModules.default ];

  services.ssh-keys-manager = {
    enable = true;
    keysDirectory = ../../../ssh-keys;
    username = "deepwatrcreatur"; # Explicitly define the user to apply keys to
    enableDynamicKeys = true;     # Enables the hybrid approach
  };
}
```

**Usage:**
- NixOS manages keys from `ssh-keys/*.pub` → `~/.ssh/authorized_keys` (read-only)
- You manually add keys → `~/.ssh/authorized_keys_dynamic` (writable)
- The SSH daemon is configured to check both files.

### 2. Home-Manager Module (`known_hosts`)

The Home Manager module is used to parse the SSH config and deploy a managed `known_hosts` file across systems.

```nix
{
  imports = [ inputs.ssh-keys-manager.homeManagerModules.default ];

  programs.ssh-known-hosts-manager = {
    enable = true;
    keysDirectory = ../../../ssh-keys;
    sshConfigFile = ../ssh-config;
    outputFile = ".ssh/known_hosts_managed";
  };
}
```

## Adding a New Key

1. Copy the new `.pub` key to the `ssh-keys/` directory.
   - Use the convention `{hostname}-host-ed25519.pub` for host keys.
   - Use the convention `{username}@{hostname}-ed25519.pub` for user keys.
2. Commit the key to Git.
3. Rebuild the affected hosts.

## For agenix secrets.nix automation

You can auto-generate `secrets.nix` for Agenix from the `ssh-keys` directory.

The repository includes scripts to collect host keys and auto-generate the `secrets.nix` file:

1. **Collect host keys:**
   ```bash
   ./scripts/agenix/collect-host-keys.sh
   ```

2. **Generate secrets.nix:**
   ```bash
   ./scripts/agenix/generate-secrets-nix.sh
   ```