# Router Standby and Management IPv6 RA Suppression

Status: `done`
Priority: `high`
Branch: `fix/router-standby-and-mgmt-ipv6-ra-suppression`

## Goal

Suppress rogue IPv6 Router Advertisements (RAs) originating from the standby router (`router-backup`) and the router's management interface (`ens18`), preventing multipath routing table poisoning and intermittent IPv6 packet blackholing on downstream LAN clients.

## Why

During diagnostic testing (`ping google.com` vs `ping google.ca`), LAN clients experienced 100% packet loss to `google.ca` over IPv6 while `google.com` succeeded. Investigation revealed:
1. `router-backup` runs as an active Proxmox VM without a WAN uplink (`ens27` is absent/unattached).
2. `router-backup` imported the router role with `services.router-networking` enabled, which caused `systemd-networkd` to broadcast Router Advertisements claiming default router reachability on its LAN interface (`ens19`).
3. The router's management interface (`ens18`) was also configured as a routed interface with prefix delegation and active RA broadcasting, sending RAs for `2607:...:7b01::/64` onto the shared broadcast domain.
4. Downstream clients installed four equal-cost multipath (ECMP) default routes: two to the active router, and two to the standby VM without WAN. Whenever client IPv6 flow hashing selected `router-backup`, all outbound packets were silently blackholed.

## Scope

- In `hosts/nixos/router/role.nix`:
  - Suppress RA broadcasting and DHCP prefix delegation on the management interface (`20-router-management`).
  - When `!ownLanServices && !enableHa`, ensure the standby node suppresses RA broadcasting on its LAN interface (`20-router-lan`).
- In `hosts/nixos/router-backup/configuration.nix`:
  - Explicitly force `IPv6SendRA = false` and `DHCPPrefixDelegation = false` on both `20-router-lan` and `20-router-management`.
- Validate that `router` and `router-backup` evaluate cleanly.

## Non-Goals

- Reworking Keepalived VRRP failover (which remains deferred until standby WAN hardware is attached).
- Modifying IPv4 DHCP / Kea lease allocation logic.

## Validation

- `nix eval .#nixosConfigurations.router.config.systemd.network.networks."20-router-management".networkConfig.IPv6SendRA` -> `false` (verified)
- `nix eval .#nixosConfigurations.router-backup.config.systemd.network.networks."20-router-lan".networkConfig.IPv6SendRA` -> `false` (verified)
- `nix eval .#nixosConfigurations.router-backup.config.systemd.network.networks."20-router-management".networkConfig.IPv6SendRA` -> `false` (verified)
- `nix eval .#nixosConfigurations.router.config.systemd.network.networks."20-router-lan".networkConfig.IPv6SendRA` -> `true` (verified)
- `DHCPPrefixDelegation` is also verified `false` on management and standby LAN.

## Outcome

- Updated `hosts/nixos/router/role.nix` to disable RA and PD on management (`20-router-management`), and conditionally suppress them on LAN when running as a non-HA standby node (`!ownLanServices && !enableHa`).
- Updated `hosts/nixos/router-backup/configuration.nix` with explicit overrides on both LAN and management.
- Evaluated both `router` and `router-backup` configurations with zero errors.
