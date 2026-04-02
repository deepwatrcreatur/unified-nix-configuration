# Migrating from IP-based to Hostname-based SSH Config

Historical note: this is a migration/reference document. It explains the move
from older SSH/DNS patterns to the current hostname-based model, but it is not
the primary source of truth for the live router/network split.

## Current State (IP-based)

Your current SSH config in `modules/home-manager/ssh-config`:

```ssh-config
Host router
    Hostname 10.10.10.1
    user deepwatrcreatur

```

## New State (Hostname-based with DNS)

After DNS zone module is active:

```ssh-config
Host router
    Hostname router.deepwatercreature.com
    user deepwatrcreatur

```

## Benefits

1. **Change IPs without updating SSH config**
   - Update DNS record in one place
   - SSH config continues to work

2. **Consistent naming everywhere**
   - Same hostname in SSH, web browsers, ping
   - No more remembering IPs

3. **DNS-based service discovery**
   - New services announce themselves via DNS
   - Clients discover via hostname

## Migration Steps

### Step 1: Verify DNS is working

```bash
# On any host with router as DNS server
dig router.deepwatercreature.com
# Should return the correct IP
# router.deepwatercreature.com -> 10.10.10.1
```

### Step 2: Update SSH config to use hostnames

Edit `modules/home-manager/ssh-config`:

```nix
{
  programs.ssh = {
    enable = true;
    
    matchBlocks = {
      "router" = {
        hostname = "router.deepwatercreature.com";
        user = "deepwatrcreatur";
      };
      
      # ... repeat for all hosts
    };
  };
}
```

### Step 3: Test connections

```bash
# Should work exactly as before
ssh router
```

### Step 4: Update other tools

**Ansible inventories:**
```yaml
all:
  hosts:
    router:
      ansible_host: router.deepwatercreature.com
```

**Nix remote builders:**
```nix
nix.buildMachines = [{
  hostName = "attic-cache.deepwatercreature.com";  # Instead of 10.10.11.39
  system = "x86_64-linux";
  # ...
}];
```

**Nix substituters:**
```nix
nix.settings.substituters = [
  "http://attic-cache.deepwatercreature.com:5001/cache-local"
];
```

## Handling DNS Fallback

If DNS is temporarily down, you can still use IPs by having both entries:

```ssh-config
Host router
    Hostname router.deepwatercreature.com
    user deepwatrcreatur

Host router-ip
    Hostname 10.10.10.1
    user deepwatrcreatur
```

Then use `ssh router-ip` as fallback.

## Short Names vs FQDNs

You have two options:

### Option 1: Short names (recommended)

Configure DNS search domain in `networking.nix`:

```nix
networking.domain = "deepwatercreature.com";
networking.search = [ "deepwatercreature.com" ];
```

Then use short names everywhere:
```bash
ssh router          # Resolves to router.deepwatercreature.com
```

### Option 2: Always use FQDNs

More explicit, works anywhere:
```bash
ssh router.deepwatercreature.com
```

## What About Hosts Not in DNS Yet?

During migration, some hosts may not be in DNS. You can:

1. **Keep IP-based entries temporarily**
   ```ssh-config
   Host old-server
       Hostname 10.10.11.99  # Not in DNS yet
       user root
   ```

2. **Add to DNS gradually**
   - Add host to `staticHosts` in router config
   - Rebuild router
   - Update SSH config to use hostname

3. **Use `/etc/hosts` as bridge**
   ```nix
   networking.hosts = {
     "10.10.11.99" = [ "old-server.deepwatercreature.com" ];
   };
   ```

## Verification Checklist

- [ ] All static hosts resolve via DNS
- [ ] DHCP dynamic hosts still work
- [ ] SSH connections work with hostnames
- [ ] Remote builds use hostname
- [ ] Substituters use hostname
- [ ] Monitoring/alerting uses hostnames
- [ ] Backup systems use hostnames

## Rollback Plan

If something breaks:

1. **Revert SSH config** to IP-based temporarily
2. **Check DNS server** is running: `systemctl status technitium-dns-server`
3. **Check DNS sync** service: `systemctl status technitium-sync-static-hosts`
4. **Manual DNS test**: `dig @10.10.10.1 router.deepwatercreature.com`

## Final State

After full migration:

- **DNS**: Single source of truth for all hosts
- **SSH**: Uses hostnames everywhere
- **Nix**: Remote builders and substituters use DNS
- **Monitoring**: Queries via hostname
- **Flexibility**: Change IPs without touching configs

Your infrastructure is now DNS-native!
