# Router Caddy Split-DNS ACME Propagation Repair

Status: `done`
Priority: `high`
Branch: `fix/router-caddy-split-dns-acme-repair`

## Goal

Resolve the ACME certificate acquisition failure in Caddy on the router so that
`https://scrypted.deepwatercreature.com` and other subdomains obtain valid TLS
certificates and reverse-proxy properly without requiring direct LAN IP access
(`10.10.11.85:10443`).

## Why

Accessing `https://scrypted.deepwatercreature.com` fails with a TLS handshake
internal error:

- `curl: (35) TLS connect error: error:0A000438:SSL routines::tlsv1 alert internal error`

Investigation revealed that Caddy has zero valid certificates in
`/var/lib/caddy/` and is holding stale locks. Caddy's ACME DNS-01 challenge
attempts with Cloudflare fail during CertMagic's propagation check:

```
[scrypted.deepwatercreature.com] Obtain: ... solving challenges: waiting for solver certmagic.solverWrapper to be ready:
checking DNS propagation of "_acme-challenge.scrypted.deepwatercreature.com." ...
querying authoritative nameservers: read udp [2607:fea8:a4e2:7b00:76:c6ff:fe01:2aaf]:...->[2607:fea8:a4e2:7b00:76:c6ff:fe01:2aaf]:53:
read: connection refused
```

### Root Cause
1. Technitium DNS server is running locally on the router and serves an internal
   split-horizon zone for `deepwatercreature.com`.
2. When querying for authoritative nameservers (`NS deepwatercreature.com`),
   Technitium returns `router.`, which resolves to the router's IPv6 LAN address
   `2607:fea8:a4e2:7b00:76:c6ff:fe01:2aaf`.
3. Technitium only listens on IPv4 (`127.0.0.1:53` and `10.10.10.1:53`), so
   DNS queries to the IPv6 address receive ICMP connection refused.
4. Furthermore, even if Technitium replied, it does not have the ACME TXT record
   because Caddy created the TXT record on Cloudflare's public nameservers
   (`jaziel.ns.cloudflare.com` / `stevie.ns.cloudflare.com`). CertMagic's
   default propagation check fails because it queries the local split-horizon
   server rather than public DNS.

## Scope

- In [`hosts/nixos/router/caddy.nix`](file:///home/deepwatrcreatur/flakes-worktrees/unified-nix-configuration/main/hosts/nixos/router/caddy.nix):
  - Configure Caddy's ACME DNS challenge to use explicit public resolvers
    (`1.1.1.1:53`, `8.8.8.8:53`) or configure `propagation_timeout -1` /
    `resolvers` in Caddy's TLS configuration so CertMagic bypasses internal
    Technitium for Cloudflare TXT validation.
- Clean up any stale cert acquisition locks in
  `/var/lib/caddy/.local/share/caddy/locks/` on the live router.
- Verify Technitium IPv6 listening configuration or ensure ACME verification
  traffic never routes to the internal zone.
- Verify reverse proxy functionality to Scrypted (`10.10.11.85:10443`).

## Non-Goals

- Changing the underlying Technitium DNS architecture or removing the internal
  zone.
- Modifying Caddy reverse proxy upstream endpoints or ports.
- Disabling HTTPS or using plaintext HTTP for Scrypted.

## Validation

- Caddy successfully completes ACME DNS-01 challenge for
  `scrypted.deepwatercreature.com` (and other configured domains).
- `curl -Iv https://scrypted.deepwatercreature.com` succeeds with HTTP 200 or
  valid redirect over TLS without alert 592.
- No `read: connection refused` or `could not get certificate from issuer` in
  `journalctl -u caddy`.

## Resolution & Live Verification

- Merged PR #193 (`fix(router): configure public resolvers for Caddy ACME DNS challenge under split-horizon DNS`).
- Deployed Generation 2 to baremetal router (`10.10.10.1`).
- Cleared stale lock files in `/var/lib/caddy/.local/share/caddy/locks/`.
- Restarted `caddy.service`. Caddy successfully obtained Let's Encrypt certificates via Cloudflare DNS-01 validation.
- Verified live with `curl -Iv https://scrypted.deepwatercreature.com`: TLS 1.3 handshake succeeded with valid Let's Encrypt certificate, returning `HTTP/2 302` redirect to `./endpoint/@scrypted/core/public/`.
