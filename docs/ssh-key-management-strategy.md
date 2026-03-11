# SSH Key Management Strategy

## Current Setup

You already auto-populate `authorized_keys` from `ssh-keys/*.pub` files - this is good! But you're concerned about:
1. File becoming read-only (nix store symlink)
2. Can't add new keys dynamically (e.g., GitHub prompts)

## Solutions

### Option 1: Hybrid approach (Recommended)
Combine NixOS-managed keys with dynamic keys:

```nix
users.users.deepwatrcreatur = {
  openssh.authorizedKeys.keys = pubKeys;  # From ssh-keys/*.pub
};

# Allow additional keys in a mutable location
systemd.tmpfiles.rules = [
  "d /home/deepwatrcreatur/.ssh 0700 deepwatrcreatur users - -"
  "f /home/deepwatrcreatur/.ssh/authorized_keys_dynamic 0600 deepwatrcreatur users - -"
];

# SSH config to check both files
services.openssh.extraConfig = ''
  # Check both NixOS-managed and user-managed keys
  AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys_dynamic
'';
```

**Usage:**
- NixOS manages keys from `ssh-keys/*.pub` → `~/.ssh/authorized_keys` (read-only)
- You manually add keys → `~/.ssh/authorized_keys_dynamic` (writable)
- SSH checks both files

### Option 2: Git-based workflow (Your current implicit approach)
Keep doing what you do now:
1. Get prompted for new key (e.g., GitHub)
2. Copy key to `ssh-keys/username@host.pub`
3. Commit to git
4. Rebuild affected hosts

**This is fine!** It's declarative and version-controlled.

### Option 3: Make authorized_keys mutable
```nix
home.file.".ssh/authorized_keys" = {
  text = lib.concatStringsSep "\n" pubKeys;
  # Don't use source, use text - creates mutable file
};

# Ensure directory permissions
home.file.".ssh/.keep".text = "";
home.file.".ssh/.keep".onChange = ''
  chmod 700 ~/.ssh
  chmod 600 ~/.ssh/authorized_keys 2>/dev/null || true
'';
```

This pre-populates but stays mutable so you can `echo "key" >> ~/.ssh/authorized_keys`.

## For agenix secrets.nix automation

**Yes, you can auto-generate from ssh-keys directory!**

```nix
# secrets.nix
let
  sshKeysDir = ./ssh-keys;
  
  # Read all pub keys and create attrset
  readKeys = dir: 
    let
      entries = builtins.readDir dir;
      pubFiles = lib.filterAttrs (name: type: 
        type == "regular" && lib.hasSuffix ".pub" name
      ) entries;
    in
    lib.mapAttrs (name: _: 
      lib.strings.trim (builtins.readFile (dir + "/${name}"))
    ) pubFiles;
  
  keys = readKeys sshKeysDir;
  
  # Extract by pattern
  hostKeys = lib.filterAttrs (name: _: lib.hasPrefix "root@" name) keys;
  userKeys = lib.filterAttrs (name: _: lib.hasPrefix "deepwatrcreatur@" name) keys;
  
  # Convenient groups
  allHostKeys = builtins.attrValues hostKeys;
  allUserKeys = builtins.attrValues userKeys;
  allKeys = allHostKeys ++ allUserKeys;
in
{
  "technitium-api-key.age".publicKeys = allKeys;
  "github-token.age".publicKeys = allKeys;
  # etc...
}
```

**But note:** Your ssh-keys has **user keys from various hosts**, not SSH **host keys**. For agenix, you need:
- **Host keys:** `/etc/ssh/ssh_host_ed25519_key.pub` from each system
- **User keys:** Your personal `~/.ssh/id_ed25519.pub`

## Action Items

1. **Collect host keys:**
   ```bash
   ssh gateway "cat /etc/ssh/ssh_host_ed25519_key.pub" > ssh-keys/gateway-host-ed25519.pub
   ssh homeserver "cat /etc/ssh/ssh_host_ed25519_key.pub" > ssh-keys/homeserver-host-ed25519.pub
   ```

2. **Create convention:** `{hostname}-host-ed25519.pub` for host keys vs `user@host-ed25519.pub` for user keys

3. **Auto-generate secrets.nix** from these files

Want me to implement the auto-generation script and hybrid authorized_keys approach?
