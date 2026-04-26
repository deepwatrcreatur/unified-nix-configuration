# 37 Kea HA Pair Deployment Completion

Status: `ready`
Suggested branch: `fix/kea-ha-pair-deployment`
Priority: `high`

## Goal

Deploy `router-backup` to the same LAN-plane HA config as `router`, verify
both nodes converge to `LOAD-BALANCING` state, and close the 2026-04-23
incident.

## Background

The incident is currently ACTIVE. The software fixes are staged and validated
(see `docs/kea-vrrp-regression-postmortem.md`), but live deployment is
incomplete:

- `router` is targeting LAN-plane HA: `http://10.10.10.3:8000/`
- `router-backup` is still on management-plane HA: `http://192.168.100.100:8000/`

Until both nodes run the same config, HA heartbeat will fail and the pair
cannot reach `LOAD-BALANCING`.

## Scope

### 1. Confirm router-backup has LAN carrier

Before deploying, confirm `enp3s0` (LAN) has carrier and the `10.10.10.3/16`
address is live on `router-backup`:

```bash
ssh root@router-backup "ip addr show enp3s0; cat /sys/class/net/enp3s0/carrier"
```

If carrier is absent, do not proceed — the LAN-plane HA addresses will be
unreachable and the node will flip Kea into constant heartbeat failure.

### 2. Deploy router-backup

```bash
cd /home/deepwatrcreatur/flakes/unified-nix-configuration-router-pr
nixos-rebuild test \
  --override-input nix-router-optimized path:/home/deepwatrcreatur/flakes/nix-router-optimized \
  --flake .#router-backup \
  --target-host root@router-backup
```

### 3. Post-deploy verification (both nodes)

Run on both routers after deploy:

```bash
# Confirm rendered HA config
kea-shell --host 127.0.0.1 --port 8000 --service dhcp4 config-get \
  | jq '.arguments["Dhcp4"]["hooks-libraries"][].parameters["high-availability"][0].peers'

# Confirm HA state
kea-shell --host 127.0.0.1 --port 8000 --service dhcp4 ha-heartbeat

# Confirm socket shape
ss -uapn 'sport = :67'

# Confirm list-commands includes lease sync
kea-shell --host 127.0.0.1 --port 8000 --service dhcp4 list-commands \
  | jq '.arguments | map(select(startswith("lease4")))'
```

### 4. Success criteria

- Both nodes expose `http://10.10.10.2:8000/` and `http://10.10.10.3:8000/`
  respectively in their rendered HA peer lists
- HA heartbeat succeeds between them (no `No route to host`)
- Both nodes reach `load-balancing` state within `max-response-delay` (60s)
- Fresh DHCP client (phone or laptop) receives a lease from whichever node is
  active

### 5. Close the incident

Once success criteria are met:
- Update `docs/incidents/2026-04-23-dhcp-vrrp-regression/SUMMARY.md` status to
  `RESOLVED` with a post-deploy verification ledger entry
- Commit and push the staged source changes from
  `unified-nix-configuration-router-pr` to the main branch via PR

## Non-Goals

- Further Kea HA feature work (Stork, cutover from Technitium DHCP) — those are
  separate items
- Full release tagging of `nix-router-optimized` — can follow in a separate
  commit

## Failure Recovery

If HA heartbeat still fails after matching deployment:
1. Re-run Phase 2 probes from `SOP_FORENSIC_ENGINEERING.md` on both nodes
2. Confirm both Kea processes are listening on `:8000` (not `127.0.0.1:8000`)
   with `ss -tlnp 'sport = :8000'`
3. Confirm no nftables rule is blocking TCP 8000 between the two LAN IPs
4. Do not mark the incident resolved until E34-equivalent strace and
   HA heartbeat evidence is in the ledger

## Dependencies

None — source changes are already staged and build-validated (E41).
