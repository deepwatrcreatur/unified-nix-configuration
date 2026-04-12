# DHCP Provider Pluggable Observability

Status: `done`
Suggested branch: `design/router-dhcp-provider-observability`
Priority: `medium`

## Goal

Design the provider boundary for DHCP observability so the router dashboard and
related diagnostics can report leases and DHCP health correctly whether the
router is using Technitium or Kea.

## Why This Matters

The current dashboard and diagnostics implicitly assume Technitium is the DHCP
engine. That assumption will not survive a clean Kea transition, and it is
already creating coupling between:

- DHCP provider selection in router config
- lease reporting in the dashboard
- DHCP health/operator workflows

If the provider is meant to be switchable, the observability/reporting layer
also needs an explicit provider boundary instead of hardcoded Technitium API
calls.

## Proposed Data Model (Provider-Agnostic)

A common JSON structure located at `/run/router/dhcp-status.json` should include:

```json
{
  "available": true,
  "provider": "technitium",
  "lastUpdated": "2026-04-09T12:00:00Z",
  "scopes": [
    {
      "name": "LAN",
      "interface": "ens16",
      "enabled": true,
      "startAddress": "10.10.10.100",
      "endAddress": "10.10.10.250",
      "leaseCount": 15
    }
  ],
  "leases": [
    {
      "address": "10.10.11.39",
      "hostname": "attic-cache",
      "hardwareAddress": "BC:24:11:CE:9D:D6",
      "leaseExpires": "2026-04-10T12:00:00Z",
      "type": "reserved",
      "scope": "LAN"
    }
  ]
}
```

## Proposed Architecture

1.  **State Snapshot Model:** Instead of the dashboard making live API calls to
    the provider, a dedicated sidecar service will poll the active provider and
    write a normalized `/run/router/dhcp-status.json` file.
2.  **Provider Scripts:**
    - `router-dhcp-poll-technitium.py`: already partially implemented in dashboard logic.
    - `router-dhcp-poll-kea.py`: future work using Kea Control Agent.
3.  **Dashboard/CLI Consumption:**
    - Both `router-dashboard` and `router-diag` will read the JSON file.
    - If the file is stale or missing, they report "DHCP data unavailable".

## Tasks for Implementation

- [ ] **Phase 1: Extraction (Upstream)**
  - Move Technitium lease-fetching logic out of `server.py` into a standalone
    `router-dhcp-poll-technitium` script in `nix-router-optimized`.
  - Add a systemd timer/service to run this script periodically.
  - Update `router-dashboard` to read the JSON file instead of calling the API.
- [ ] **Phase 2: CLI Integration (Upstream)**
  - Add `router-diag show dhcp` which consumes the same JSON file.
- [ ] **Phase 3: Kea Support (Future)**
  - Implement `router-dhcp-poll-kea` when the Kea module is ready.

## Constraints

- The dashboard should not fail if the JSON file is missing; it should show a
  clean "Data Unavailable" state.
- The JSON file must be readable by the `router-dashboard` user.

## Validation

- `router-diag show dhcp` returns accurate results from the JSON file.
- Dashboard lease list remains functional after removing Technitium credentials
  from the dashboard environment.

