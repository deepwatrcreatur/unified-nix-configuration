# 12 Nightscout Privacy and RBAC Hardening

Status: `ready`
Suggested branch: `feat/nightscout-rbac-hardening`
Priority: `high`

## Goal

Harden the Nightscout CGM homelab deployment on `podman` and `router` from unauthenticated world-readable access (`AUTH_DEFAULT_ROLES = "readable"`) to zero-trust token-based authentication (`AUTH_DEFAULT_ROLES = "denied"`), while preserving seamless telemetry upload and mobile viewer access across xDrip+, Nightguard, Loop/Trio, and terminal displays.

## Why

1. **Medical Telemetry Privacy**: Real-time continuous glucose monitor (CGM) readings, trend vectors, insulin dosages, and treatment profiles represent sensitive personal health data. Currently, `AUTH_DEFAULT_ROLES = "readable"` in `hosts/nixos-lxc/podman/stacks/nightscout-stack.nix` exposes live BG readings to anyone visiting `https://nightscout.deepwatercreature.com` without authentication.
2. **Crawler & Bot Exposure**: Search engine crawlers and internet scanners index public subdomains, leaking private telemetry and causing unnecessary container wakeups and MongoDB queries.
3. **Native Mobile App Compatibility**: Mobile CGM apps (xDrip+, Loop, Trio, Nightguard, Garmin widgets, Apple Watch complications) natively support Nightscout Subject Tokens via HTTP header (`api-secret: <token>`) or query parameter (`?token=<token>`). They do **not** require world-readable anonymous access.
4. **Least-Privilege Token Isolation**: Using granular Subject Tokens allows isolating read-only viewer clients (e.g. headless laptop display, phone widgets) from write-capable uploader bridges (e.g. LibreLinkUp sync). Tokens can be rotated independently without compromising or changing the master `API_SECRET`.

## Architectural Context

```
Internet / LAN ──▶ Caddy (router:443) ──▶ Nightscout (podman:11337)
                                              │
                      ┌───────────────────────┴───────────────────────┐
                      ▼                                               ▼
              AUTH_DEFAULT_ROLES="denied"                 Subject Tokens (RBAC)
                      │                                               │
             Unauthenticated Visitor                         Authenticated Clients
             - Status: 401 Unauthorized                      - Phone Apps: ?token=xxx
             - Web UI: Authentication Prompt                 - Laptop Display: --token xxx
             - Scanners/Bots Blocked                         - LibreLinkUp: API_SECRET
```

## Scope

1. **Nightscout Stack Hardening (`hosts/nixos-lxc/podman/stacks/nightscout-stack.nix`)**:
   - Change `AUTH_DEFAULT_ROLES = "readable";` to `AUTH_DEFAULT_ROLES = "denied";`.
   - Ensure `API_SECRET` secret mounting remains active and verified.
2. **Provision Subject Tokens**:
   - Access Nightscout Admin Tools (`https://nightscout.deepwatercreature.com/admin`) using master `API_SECRET`.
   - Create dedicated Subject Tokens under Subjects:
     - `mobile-viewer`: Role `readable` (used by xDrip+, Nightguard, phone widgets).
     - `laptop-display`: Role `readable` (used by `nightscout-tui` and headless kiosk).
     - `bridge-uploader`: Role `api:*:create` / `uploader` (if separate from `API_SECRET`).
3. **Verify Bridge Integrations**:
   - Verify `hosts/nixos-lxc/podman/stacks/librelinkup-stack.nix` continues to authenticate properly using `API_SECRET`.
4. **Router Reverse Proxy Hardening (`hosts/nixos/router/caddy.nix`)**:
   - Add rate-limiting policies or path-based filtering if needed to suppress automated scanner probes on sensitive admin routes.
   - Ensure TLS and websocket connections (`/socket.io`) pass through cleanly for real-time mobile app updates.

## Validation

- Unauthenticated browser visiting `https://nightscout.deepwatercreature.com` receives a login prompt and cannot see glucose readings.
- Browser visiting `https://nightscout.deepwatercreature.com/?token=<subject_token>` successfully authenticates and renders the live dashboard.
- Unauthenticated API call `curl -i "https://nightscout.deepwatercreature.com/api/v1/entries.json"` returns `401 Unauthorized`.
- Authenticated API call `curl -i -H "api-secret: <token>" "https://nightscout.deepwatercreature.com/api/v1/entries.json?count=1"` returns `200 OK` with JSON telemetry.
- Mobile apps (xDrip+, Nightguard) update successfully with the configured token.
- LibreLinkUp bridge continues uploading CGM entries every 5 minutes.
