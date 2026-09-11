# Router Pangolin Service Hardening & Permissions Repair

Status: `in-progress`
Priority: `high`
Branch: `fix/router-pangolin-service-hardening`

## Goal

Resolve the crash-restart loop of `pangolin.service` on the router (restart
counter >28,000) so that the Pangolin reverse-proxy tunneling service starts
cleanly and reaches `active (running)`.

## Why

Checking service status on the live router revealed that `pangolin.service` was
restarting continuously every few seconds with restart counter >28,200.

### Root Causes
1. **Systemd SocketBindDeny Conflict**:
   The generated systemd service configuration in nixpkgs includes:
   ```ini
   SocketBindDeny=ipv4:tcp
   SocketBindDeny=ipv4:udp
   SocketBindDeny=ipv6:udp
   ```
   However, `/var/lib/pangolin/config/config.yml` explicitly instructs Pangolin
   to bind internal and external TCP ports on IPv4 localhost (`3000`, `3001`, `3002`, `3003`).
   The `SocketBindDeny=ipv4:tcp` directive prevents the Node/Next process from
   binding any of its listening ports.

2. **Read-Only Permissions on `.next` Directory & Setup Marker**:
   During service initialization, the upstream package wrapper script runs:
   `cp -rd .../share/pangolin/.next .`
   This copies `.next` with read-only permissions (`0555`). On subsequent restarts
   without `.next/.nix_skip_setup`, it attempts `rm -rf .next` and fails with:
   `rm: cannot remove '.next/static/...': Permission denied`.
   Creating `.next/.nix_skip_setup` and setting write permissions `chmod -R u+rwX .next`
   resolves this loop.

3. **Port Conflict on Port 3001**:
   Pangolin's default `internal_port` is `3001`. On this router, Grafana is already
   listening on `*:3001`. When Pangolin attempts to start its internal API server,
   it crashes with `Error: listen EADDRINUSE: address already in use :::3001`.
   Configuring `services.router-pangolin.settings.server.internal_port = 3005` resolves
   the collision cleanly.

4. **Missing Server Secret**:
   Pangolin requires `SERVER_SECRET` in `/etc/pangolin/pangolin.env` (or in `config.yml`).
   Without this file, startup fails with `Error: Validation error: Server secret must be defined`.

5. **Missing Database JSON Files in `server/db/`**:
   The packaged `server.mjs` synchronously reads `server/db/names.json`, `server/db/ios_models.json`,
   and `server/db/mac_models.json` relative to its working directory. These files reside in
   `share/pangolin/dist/*.json` and must be symlinked into `/var/lib/pangolin/server/db/`.

6. **UDP GRO Forwarding for Tailscale Exit Node**:
   When using Tailscale with `--advertise-exit-node`, the kernel requires UDP GRO forwarding:
   `ethtool -K <iface> rx-udp-gro-forwarding on rx-gro-list off`.

## Scope

- In [`hosts/nixos/router/role.nix`](file:///home/deepwatrcreatur/flakes-worktrees/unified-nix-configuration/main/hosts/nixos/router/role.nix):
  - Configure `services.router-pangolin.settings.server.internal_port = 3005` to avoid
    the port 3001 conflict with Grafana.
  - Override `systemd.services.pangolin.serviceConfig.SocketBindDeny` to omit `ipv4:tcp`.
  - Add `preStart` script to:
    - Auto-provision `/etc/pangolin/pangolin.env` with a secure random `SERVER_SECRET` if not present.
    - Fix permissions on `/var/lib/pangolin/.next` and touch `/var/lib/pangolin/.next/.nix_skip_setup`.
    - Symlink `${package}/share/pangolin/dist/*.json` into `/var/lib/pangolin/server/db/`.
  - Add `router-hardware-offload.postStart` to apply `rx-udp-gro-forwarding on rx-gro-list off`
    to WAN, LAN, and Management interfaces.

## Non-Goals

- Exposing Pangolin management interfaces to the untrusted WAN.
- Altering other unrelated systemd hardening directives (e.g. `ProtectSystem=full`, `PrivateDevices`).

## Validation

- `systemctl status pangolin.service` reports `active (running)` without continuous restarts.
- `journalctl -u pangolin` shows clean startup without socket bind errors or permission denied logs.
- `curl -Iv http://127.0.0.1:3002/` returns `HTTP/1.1 200 OK` from Next.js Web UI.
- `curl -Iv http://127.0.0.1:3000/api/v1/health` responds from API server.
- `tailscale up --advertise-exit-node --advertise-routes=10.10.0.0/16` runs without UDP GRO warnings.
