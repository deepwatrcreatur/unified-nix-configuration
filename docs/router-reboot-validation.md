# Router Reboot Validation

Use this runbook after a planned `router` reboot.

This is intentionally scoped to the **current production shape**:

- `router` is the only active production router
- `router-backup` is a cold/manual spare
- HA, VRRP, and WAN failover are deferred future work

The goal is simple:

- confirm the router actually booted the intended generation
- confirm WAN, DNS, and DHCP are usable for clients
- catch regressions before you start changing more things

## Before Reboot

Record the two values you expect to compare after boot:

```bash
readlink -f /run/current-system
readlink -f /nix/var/nix/profiles/system
```

Make sure you still have:

- a management-path SSH session or console for `router`
- a LAN-side client to test from
- a known-good fallback generation if the reboot fails

## Router-Local Checks

As soon as `router` comes back, confirm it booted the intended closure:

```bash
readlink -f /run/current-system
readlink -f /nix/var/nix/profiles/system
```

For a successful boot, those should match.

Then check the core services:

```bash
systemctl is-active systemd-networkd caddy technitium-dns-server kea-dhcp4-server kea-dhcp-ddns-server
systemctl is-active keepalived suricata router-evebox
systemctl --failed
```

Expected state in the current simplified mode:

- `systemd-networkd`: `active`
- `caddy`: `active`
- `technitium-dns-server`: `active`
- `kea-dhcp4-server`: `active`
- `kea-dhcp-ddns-server`: `active`
- `keepalived`: `inactive`
- `suricata`: `inactive`
- `router-evebox`: `inactive`

Confirm interface and route state:

```bash
ip -o -4 addr show dev enp6s16
ip route show default
```

Expected state:

- `enp6s16` owns `10.10.10.1/16`
- a default route exists through `enp6s17`

Confirm DNS and DHCP listeners are actually bound:

```bash
sudo ss -ulpn | grep -E '(:53 |:67 )'
```

Expected state:

- DNS on `127.0.0.1:53`
- DNS on `10.10.10.1:53`
- DHCP on `10.10.10.1:67`

## Basic Reachability

From `router` itself:

```bash
getent ahostsv4 github.com
ping -c 2 1.1.1.1
```

Interpretation:

- IP ping fails: WAN/routing problem
- DNS lookup fails but ping works: resolver/startup problem

## LAN-Side Checks

From a client on the LAN, verify:

- it can release and renew a DHCP lease, or obtain one as a fresh client
- it can resolve names
- it can reach the Internet

Do not rely on a client that simply kept its pre-reboot lease.
First force a lease renew or use a device that is freshly joining the LAN.
Then run the reachability checks.

Useful examples:

```bash
ping -c 2 1.1.1.1
ping -c 2 github.com
```

If a client fails to get an address, inspect live Kea activity on `router`:

```bash
journalctl -u kea-dhcp4-server --since "10 minutes ago" --no-pager -n 80
```

## What Counts As Failure

Treat the reboot as failed if any of these are true:

- `/run/current-system` did not move to the intended closure
- `systemd-networkd`, `caddy`, `technitium-dns-server`, `kea-dhcp4-server`, or
  `kea-dhcp-ddns-server` is not `active`
- `kea-dhcp4-server` is `active` but no `:67` listener exists
- `technitium-dns-server` is up but name resolution fails
- `enp6s16` does not own `10.10.10.1/16`
- the default route is missing
- LAN clients cannot renew or obtain working leases
- `systemctl --failed` reports unexpected failed units in the client path

## Recovery

If the new generation is bad:

1. stop testing additional changes
2. use console or management access
3. reboot into the last known good generation
4. restore DHCP immediately if needed by restarting Kea on the recovered generation

Example emergency DHCP recovery on the primary:

```bash
sudo systemctl restart kea-dhcp4-server
sudo ss -ulpn | grep ':67 '
```

That is a recovery action, not acceptance of the bad generation.
