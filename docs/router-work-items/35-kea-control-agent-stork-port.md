# 35 Kea Control Agent / Stork Port Conflict

Status: `ready`
Suggested branch: `feat/router-stork-agent`
Priority: `medium`

## Problem

Running ISC Kea Stork requires `kea-ctrl-agent` or direct unix socket access.
There is a port conflict between two Kea HTTP listeners that must be resolved
before Stork can be wired into the router config.

### The conflict

`kea-dhcp4` with `libdhcp_ha.so` runs an embedded HTTP server on **port 8000**
for peer HA heartbeat/sync communication. This is configured in `router-kea.nix`
as the HA peer URL:

```
http://<localAddress>:8000/
```

`kea-ctrl-agent` (the separate REST management proxy daemon) also defaults to
**port 8000**. Both cannot bind to the same IP:port.

---

## Decision

**Use Stork Agent's direct unix socket path. Do not run `kea-ctrl-agent`.**

### Rationale

Stork Agent (>= 2.x, available in current nixpkgs) can connect to Kea directly
via its unix control socket (`/run/kea/dhcp4.sock`) without requiring
`kea-ctrl-agent` as an intermediary. This:

- Eliminates the port conflict entirely — no `kea-ctrl-agent` process, no port
  contention
- Reduces the daemon count on both routers by one
- The unix socket is already configured and exposed in `router-kea.nix`:
  ```nix
  control-socket = {
    socket-type = "unix";
    socket-name = "/run/kea/dhcp4.sock";
  };
  ```
- Stork Agent reads the socket path from the Kea config file it is pointed at,
  so no additional wiring is needed beyond enabling the agent and pointing it at
  the Kea config

### Fallback

If the nixpkgs Stork package does not support the unix socket path (check with
`stork-agent --help | grep socket`), fall back to running `kea-ctrl-agent` on
**port 8001** (not the default 8000). Configure Stork Agent's Kea connectivity
to `http://localhost:8001/`. This requires:

```nix
services.kea.ctrl-agent = {
  enable = true;
  settings = {
    http-host = "127.0.0.1";
    http-port = 8001;         # not the default 8000
    control-sockets.dhcp4 = {
      socket-type = "unix";
      socket-name = "/run/kea/dhcp4.sock";
    };
  };
};
```

The firewall rule for port 8000 (HA peer) remains unchanged.

---

## Implementation Tasks

- [ ] Verify which Stork version is in nixpkgs and whether it supports unix
  socket connectivity without `kea-ctrl-agent`
  ```bash
  nix eval nixpkgs#stork.version
  ```
- [ ] Add `services.stork-agent` to `nix-router-optimized/modules/router-kea.nix`
  under `mkIf cfg.dhcp4.ha.enable` (Stork is only meaningful in multi-node
  setups). Point it at the Kea DHCPv4 config file.
- [ ] Wire the Stork agent to the correct Stork Server address. In the VRRP
  topology this will be the LAN VIP (`10.10.10.1`) — see work item 36.
- [ ] Add a firewall rule to permit Stork agent→server gRPC traffic (port 8080
  or as configured by the server) from LAN-plane addresses.
- [ ] Validate: `stork-agent status` reports connected; Stork Server dashboard
  shows both routers' Kea instances.

## Dependencies

- Work item 36 (Stork VRRP HA) must define the server address before this item
  can be wired end-to-end, but the agent-side changes can be developed
  independently.

## Non-Goals

- Running `kea-ctrl-agent` (see decision above)
- Monitoring Kea DHCPv6 (not deployed)
