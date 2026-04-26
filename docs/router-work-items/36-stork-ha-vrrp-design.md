# 36 Stork Server VRRP High Availability

Status: `ready`
Suggested branch: `feat/router-stork-server-ha`
Priority: `medium`

## Goal

Deploy ISC Kea Stork (the Kea cluster dashboard) with high availability using
the existing VRRP/keepalived infrastructure. Stork should be accessible at a
stable address regardless of which router is currently primary.

## Background

Stork has two components:
- **stork-agent**: Runs on each Kea host. Connects to Kea via its unix control
  socket. Pushes lease/pool/HA state to the server. Reconnects automatically.
- **stork-server**: The web dashboard + gRPC receiver. Stores state in a
  database. Must be reachable by all agents.

The question is where to run the server and how to make it survive a failover.

---

## Design: VRRP Notify-Controlled Server

### Core idea

Run `stork-server` on whichever router currently holds the VRRP primary role.
keepalived's `notify_master` / `notify_backup` scripts start and stop the
`stork-server.service` unit as the router transitions roles. Agents connect to
the Stork server via the existing LAN VRRP VIP (`10.10.10.1`).

```
                    10.10.10.1 (VRRP VIP, floats)
                          │
              ┌───────────┴───────────┐
              │                       │
         router                 router-backup
     stork-agent               stork-agent
     stork-server (MASTER)     [stork-server stopped]
     kea-dhcp4 (primary)       kea-dhcp4 (secondary)
```

On failover, keepalived transitions `router-backup` to MASTER:

```
         router                 router-backup
     stork-agent               stork-agent
     [stork-server stopped]    stork-server (MASTER)
     kea-dhcp4 (backup)        kea-dhcp4 (primary)
```

Agents detect the server is gone (brief gap), retry, and reconnect to the new
server within seconds. Agent re-registration is automatic in Stork >= 2.4 with
`auto-register-machine` enabled.

### Why this works

- Stork's database (SQLite, adequate for homelab scale) stores lease stats and
  agent registration. On failover, the new server instance starts with an empty
  database, but agents reconnect and re-register within one polling cycle
  (typically 10–30 seconds). Historical stats are lost, but the live view
  recovers automatically.
- No shared storage, no external database dependency.
- Reuses the existing VRRP infrastructure — no new VIP or keepalived instance
  needed.

### Why not run the server on a separate host (e.g., homeserver LXC)?

That would avoid the failover gap entirely, but it introduces an external
dependency for router observability. If the homeserver LXC is down, the
dashboard is gone even when the routers are healthy. The VRRP approach keeps
router monitoring co-located with the routers and self-contained.

---

## Implementation Tasks

### 1. Stork server NixOS module (`nix-router-optimized`)

Add `services.stork-server` gated behind a new option:
```nix
services.router-kea.stork.enable = mkEnableOption "Kea Stork dashboard server";
```

Stork server should:
- Listen on `0.0.0.0:8080` (web UI + agent gRPC)
- Use SQLite backend (no PostgreSQL dependency for homelab)
- Have `InitialAdminPassword` set via an agenix secret

### 2. keepalived notify scripts

In the keepalived (VRRP) config for the router role, add:
```
notify_master "/run/current-system/sw/bin/systemctl start stork-server.service"
notify_backup "/run/current-system/sw/bin/systemctl stop stork-server.service"
notify_fault  "/run/current-system/sw/bin/systemctl stop stork-server.service"
```

Ensure `stork-server.service` has `Restart=no` (keepalived owns the lifecycle).

The existing keepalived module in `nix-router-optimized` should expose a
`notifyMaster` / `notifyBackup` option if it does not already.

### 3. Stork agents on both routers

Wire `services.stork-agent` on both routers to connect to `10.10.10.1:8080`
(the VIP). See work item 35 for the agent-side port/socket details.

```nix
services.stork-agent = {
  enable = true;
  settings.server-url = "http://10.10.10.1:8080";
};
```

### 4. Caddy virtual host

Add `stork.deepwatercreature.com` to `hosts/nixos/router/caddy.nix`.

#### Access control decision

Stork shows the full DHCP lease table, HA state, and pool utilisation for the
entire LAN. It has operational value when debugging from off-site, but it is a
sensitive network-internal view. The decision:

- **LAN and Tailnet (`10.10.0.0/16`, `100.64.0.0/10`):** direct reverse proxy,
  no extra authentication layer. Stork's own login is sufficient on trusted
  networks.
- **WAN:** gated by Authentik `forward_auth`. Authentik authenticates the
  session before any request reaches Stork. Stork's own login follows (two
  layers; acceptable for an admin tool).

#### Caddy config shape

```nix
"${mkFqdn "stork"}" = {
  extraConfig = ''
    @trusted remote_ip ${lanNetwork.cidr} 100.64.0.0/10
    handle @trusted {
      reverse_proxy 127.0.0.1:8080
    }

    handle {
      forward_auth https://${authentikHost.ip}:9000 {
        uri /outpost.goauthentik.io/auth/caddy
        copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Email \
          X-Authentik-Name X-Authentik-Uid X-Authentik-Jwt \
          X-Authentik-Meta-Jwks X-Authentik-Meta-Outpost X-Authentik-Meta-Provider \
          X-Authentik-Meta-App X-Authentik-Meta-Version
      }
      reverse_proxy 127.0.0.1:8080
    }
  '';
};
```

Note: `forward_auth` points directly at the Authentik host IP rather than the
public `authentik.deepwatercreature.com` hostname to avoid a loopback through
Caddy's own proxy when Caddy and Authentik are on different LAN hosts.

#### Stork local authentication

**Disable Stork's built-in login entirely.** Stork supports header-based
identity via `X-Authentik-Username` (and related headers) when local auth is
turned off. The `copy_headers` block in the `forward_auth` directive already
passes these through.

Rationale:
- Stork's port 8080 is bound to `127.0.0.1`. Nothing on the network can reach
  it directly — Caddy is the only ingress.
- LAN users are family (trusted). Requiring them to manage a separate set of
  Stork credentials adds friction with no security benefit.
- The only way to forge a username header into Stork is to have code execution
  on the router itself. At that point, Stork is not the threat surface.
- Result: LAN/Tailnet users land directly on the dashboard; WAN users pass
  through Authentik once and then land directly on the dashboard. No double
  login.

Configure Stork to trust forwarded identity:
```
# in stork-server settings
enable-http-authentication = false
# or equivalent NixOS option — verify against the nixpkgs stork module
```

#### Authentik setup (manual, one-time)

Stork has no native OIDC support so it cannot use the OIDC provider pattern
used by Paperless. Use Authentik's **Proxy Provider** in
**Forward Auth (single application)** mode instead.

Steps in the Authentik UI:
1. Applications → Providers → Create → Proxy Provider
2. Mode: **Forward Auth (single application)**
3. External host: `https://stork.deepwatercreature.com`
4. Leave token validity and additional scopes at defaults
5. Create a new Application pointing at this provider
6. Assign to the **embedded outpost** (no separate outpost deployment needed)

The embedded outpost exposes
`https://authentik.deepwatercreature.com/outpost.goauthentik.io/` which Caddy's
`forward_auth` block calls. Caddy itself reaches the Authentik host directly via
its LAN IP to avoid the proxy loop.

#### DDNS

The `caddy-dynamicdns` plugin reads virtual hosts from Caddy's running config
and creates/updates DNS records automatically. Adding the virtual host is
sufficient; no manual Cloudflare record is needed.

### 5. Firewall

Port 8080 does **not** need a firewall opening. Caddy proxies to
`127.0.0.1:8080` (loopback) and Caddy's own ports (80/443) are already open.
Stork's port 8080 should remain LAN-internal — inaccessible directly from WAN.

---

## VRRP Interaction Summary

| Concern | Impact |
|---|---|
| Stork vs VRRP gateway traffic | None — Stork uses port 8080; gateway uses 80/443 via Caddy |
| Stork vs Kea HA port 8000 | None — separate ports, separate services (see work item 35) |
| Stork server restart on failover | ~10–30 second gap; agents reconnect automatically |
| Stork agent on primary while server is on backup | Works — agents always connect outbound to the VIP |
| VRRP preemption causing rapid stork-server flap | Acceptable for homelab; can be mitigated with keepalived preempt_delay |

---

## Browsing to the Dashboard

Once deployed: `https://stork.deepwatercreature.com`

- From LAN or Tailnet: direct, no extra login prompt
- From WAN: Authentik login gate → Stork login

The dashboard shows:
- HA state of each Kea node (PRIMARY / SECONDARY / PARTNER-DOWN)
- Lease pool utilization per subnet
- Active lease count
- Connected agents

---

## Dependencies

- Work item 35 (Kea Control Agent / Stork agent port conflict) — must be resolved
  first to define how agents connect to Kea
- Existing keepalived/VRRP wiring in `nix-router-optimized` — must expose
  notify hook configuration
- Authentik Proxy Provider setup (manual one-time step, see §4 above) — must be
  completed before the WAN access path works

## Validation

- [ ] Both agents appear in the Stork dashboard
- [ ] Kea HA state on both nodes shown correctly
- [ ] Stopping `stork-server` on primary and promoting backup brings the
  dashboard back within 60 seconds at the same URL
- [ ] `https://stork.deepwatercreature.com` loads the dashboard from LAN without prompting for Authentik
- [ ] Accessing from a non-LAN IP redirects to Authentik login before reaching Stork
- [ ] Port 8080 is not directly reachable from WAN (verify with `curl http://<wan-ip>:8080` from outside)
