# Router iVentoy Runtime Repair

Status: `ready`
Priority: `high`
Branch: `fix/router-iventoy-runtime-repair`

## Goal

Restore a clean `iventoy.service` startup on the live router so the PXE ISO menu
server no longer fails immediately after activation.

## Why

During the 2026-04-21 router activation, `switch-to-configuration` reported
`iventoy.service` failed with `Result=protocol` after repeated restarts even
though its `ExecStartPre` and `ExecStart` returned success.

That leaves the router in a noisy degraded state and undermines the PXE
follow-up work by keeping the currently selected implementation unhealthy.

## Scope

- inspect the `iventoy.service` unit and wrapper script path end-to-end
- determine why systemd considers the service protocol/startup contract broken
- fix the runtime integration in the repo-owned module or host wiring, not by
  ad hoc changes on the host
- verify the service reaches and stays in `active` state after rebuild
- capture any narrow notes needed for future PXE work items if the repair
  reveals an upstream caveat

## Non-Goals

- redesigning the PXE architecture
- replacing iVentoy with another PXE stack in this PR
- broad cleanup of unrelated PXE or DHCP work

## Validation

- `systemctl status iventoy.service` reports `active`
- `journalctl -u iventoy.service -b` shows no rapid restart loop or protocol
  failure after activation
- router rebuild/test no longer reports `iventoy.service` as failed

## Notes

Observed on live `router` during activation of merged commit `3af2d70c` on
2026-04-21.
