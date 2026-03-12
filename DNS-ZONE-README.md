# DNS Zone Configuration

This file explains how DNS zone management works in this repository.

## Overview

The `dns-zone.nix` file contains static DNS records for the homelab that are:
- **Version controlled** - Track changes to your network over time
- **Declarative** - Define your network topology in code
- **Mergeable** - Works alongside DHCP dynamic updates

## File Structure

```nix
{
  domain = "deepwatercreature.com";
  
  hosts = {
    hostname = {
      ipv4 = "10.10.11.x";
      ipv6 = null;  # or IPv6 address
      aliases = [ "alias1" "alias2" ];  # Optional CNAME records
    };
  };
  
  aliases = {
    # Additional CNAMEs
    "alias" = "target-hostname";
  };
}
```

## How It Works

1. **Gateway imports** `dns-zone.nix` in its configuration
2. **Router flake** converts the format to Technitium DNS records
3. **Static records** are always present in DNS
4. **DHCP clients** can still register dynamically alongside static records

## Updating DNS Records

### Adding a New Host

1. Edit `dns-zone.nix`:
   ```nix
   hosts = {
     # ... existing hosts ...
     new-host = {
       ipv4 = "10.10.11.100";
       ipv6 = null;
       aliases = [ "alias1" ];
     };
   };
   ```

2. Commit and push:
   ```bash
   git add dns-zone.nix
   git commit -m "Add new-host to DNS"
   git push
   ```

3. Rebuild gateway:
   ```bash
   sudo nixos-rebuild switch --flake .#gateway
   ```

### Updating SSH Config

After adding hosts to DNS, you can update `.ssh/config` to use hostnames instead of IP addresses:

**Before:**
```
Host pve-gateway
    Hostname 10.10.11.52
    user root
```

**After:**
```
Host pve-gateway
    Hostname pve-gateway.deepwatercreature.com
    user root
```

## Benefits

1. **Single Source of Truth** - All static IPs in one file
2. **History** - Git tracks when hosts were added/removed/changed
3. **Documentation** - The zone file documents your network
4. **Integration** - SSH configs, firewall rules, etc. can reference hostnames
5. **Flexibility** - Static and dynamic DNS coexist

## Dynamic vs Static

- **Static (dns-zone.nix)**: Infrastructure, servers, services
- **Dynamic (DHCP)**: Laptops, phones, guest devices

Both appear in DNS queries, but only static records are version controlled.

## Testing

Test DNS resolution:
```bash
# From any host on the network
dig gateway.deepwatercreature.com
dig @10.10.10.1 pve-gateway.deepwatercreature.com

# Should resolve to configured IPs
ping gateway.deepwatercreature.com
ssh pve-gateway.deepwatercreature.com
```

## Troubleshooting

If DNS isn't resolving:

1. Check Technitium is running: `systemctl status technitium-dns-server`
2. Verify zone loaded: Check Technitium web UI at `http://gateway:5380`
3. Test local DNS: `dig @localhost hostname.deepwatercreature.com`
4. Check firewall: `sudo nft list ruleset | grep 53`
