# Router Pangolin Service Hardening & Permissions Repair

Status: `ready`
Priority: `high`
Branch: `fix/router-pangolin-service-hardening`

## Goal

Resolve the crash-restart loop of `pangolin.service` on the router (restart
counter >28,000) so that the Pangolin reverse-proxy tunneling service starts
cleanly and reaches `active (running)`.

## Why

Checking service status on the live router revealed that `pangolin.service` is
restarting continuously every few seconds:

```
● pangolin.service - Pangolin reverse proxy tunneling service
   Active: activating (start-pre) ...
   pangolin.service: Scheduled restart job, restart counter is at 28236.
```

### Root Causes
1. **Systemd SocketBindDeny Conflict**:
   The generated systemd service configuration includes:
   ```ini
   SocketBindDeny=ipv4:tcp
   SocketBindDeny=ipv4:udp
   SocketBindDeny=ipv6:udp
   ```
   However, `/var/lib/pangolin/config/config.yml` explicitly instructs Pangolin
   to bind internal and external TCP ports on IPv4 localhost:
   ```yaml
   server:
     external_port: 3000
     integration_port: 3003
     internal_hostname: localhost
     internal_port: 3001
     next_port: 3002
   ```
   The `SocketBindDeny=ipv4:tcp` directive prevents the Node/Next process from
   binding any of its listening ports.

2. **Read-Only Permissions on `.next` Directory**:
   During service initialization and Next.js migrations, Pangolin attempts to
   clean stale static chunks in `.next/static/` but fails with:
   `rm: cannot remove '.next/static/...': Permission denied` because
   `/var/lib/pangolin/.next` is owned with read-only permissions (`0555` / `dr-xr-xr-x`).

## Scope

- In the Pangolin NixOS module or router role overrides:
  - Remove or loosen `SocketBindDeny=ipv4:tcp` to permit Pangolin to bind its
    configured listening ports (`3000`, `3001`, `3002`, `3003`) on localhost/LAN.
  - Fix directory ownership and write permissions (`0750` / `0770`) for
    `/var/lib/pangolin` and its subdirectories including `.next`.
- Ensure `pangolin-pre-start` creates or adjusts needed runtime permissions.
- Validate that `pangolin.service` starts and stays running without flapping.

## Non-Goals

- Exposing Pangolin management interfaces to the untrusted WAN.
- Altering other unrelated systemd hardening directives (e.g. `ProtectSystem=full`, `PrivateDevices`).

## Validation

- `systemctl status pangolin.service` reports `active (running)` without continuous restarts.
- `journalctl -u pangolin` shows clean startup without socket bind errors or permission denied logs.
- `ss -tlpn | grep -E '3000|3001|3002|3003'` shows the service listening on its intended ports.
