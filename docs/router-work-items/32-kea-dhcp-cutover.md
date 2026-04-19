# 32 Kea DHCP Cutover

Status: `blocked`
Suggested branch: `feat/router-kea-cutover`
Priority: `high`

## Goal

Switch the router from Technitium's built-in DHCP to Kea, port all existing
reservations, enable RFC2136 DDNS registration in Technitium, and disable
Technitium DHCP so all lease-to-DNS registration flows through Kea D2.

## Why

Technitium DHCP and its DNS registration run as a single coupled unit with no
external interface. Kea D2 gives auditable, declarative lease→DNS registration
via RFC2136. Dynamic clients (phones, laptops, IoT) will finally show up by
hostname in Technitium DNS.

## Scope

### In `hosts/nixos/router/networking.nix` (or `role.nix`)

1. **Enable Kea**
   ```nix
   services.router-kea = {
     enable = true;
     dhcp4 = {
       subnet   = topology.networks.lan.cidr;
       poolRanges = [{ start = "10.10.10.100"; end = "10.10.10.250"; }];
       reservations = <ported from services.router-technitium.dhcpReservations>;
     };
     ddns = {
       enable       = true;
       tsigKeyFile  = config.age.secrets.kea-ddns-tsig-key.path;
       tsigKeyName  = "kea-ddns";
       forwardZone  = topology.domain;
       reverseZone  = "10.10.in-addr.arpa";
     };
   };
   ```

2. **Disable Technitium DHCP scopes**
   Remove or comment out `services.router-technitium.scopes`.
   Keep `services.router-technitium.dhcpReservations` empty (or remove).

3. **Enable Technitium RFC2136 via sync service**
   Add a `technitium-enable-rfc2136` systemd service (one-shot, similar to
   existing scope/reservation sync services) that:
   - POSTs `api/settings/set?tsigKeys=kea-ddns|<secret>|hmac-sha256`
   - POSTs `api/zones/options/set?zone=<domain>&update=Allow&updateNetworkACL=127.0.0.1`
     for both the forward and reverse zones
   - Reads the TSIG secret from `config.age.secrets.kea-ddns-tsig-key.path`
   - Runs after `technitium-dns-server.service` and after agenix decryption

### Reservation migration

Port `lib/hosts.nix` `dhcpReservation` entries to `services.router-kea.dhcp4.reservations`
format:
```nix
{ hw-address = host.dhcpReservation.macAddress;
  ip-address = host.ip;
  hostname   = name; }
```

## Cutover sequence (manual / one-time)

1. Deploy with both Kea and Technitium DHCP disabled → verify Kea starts clean
2. Re-enable Kea; let a few clients renew
3. Verify A records appear in Technitium for dynamic clients
4. Keep Technitium DHCP disabled permanently

## Non-Goals

- Kea HA (future item)
- Removing Technitium entirely

## Validation

- `dig @10.10.10.1 <dynamic-client-hostname>.deepwatercreature.com` resolves
- `kea-dhcp4` logs show leases being issued
- `kea-dhcp-ddns` logs show RFC2136 updates sent and `NOERROR` returned from Technitium
- Technitium web UI → Zones → `deepwatercreature.com` shows dynamically registered A records

## Dependencies

- Item 30 (TSIG key secret) — must be merged first
- Item 31 (router-kea module) — must be merged first
