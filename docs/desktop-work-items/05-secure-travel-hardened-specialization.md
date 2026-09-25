# 05 Secure-Travel Hardened Specialization Aspect

Status: `done`
Suggested branch: `feat/aspect-secure-travel`
Priority: `low` (dormant on desktops)

## Goal

Add a hardened mobile/travel specialization module & aspect (`den/aspects/secure-travel.nix`) to the repository for future use, leaving it dormant (disabled) on current desktop hosts (`phoenix`, `emerald`).

## Why

When traveling with mobile laptops (or connecting to untrusted networks such as hotels, conferences, or airports), having a hardened bootloader specialization provides network privacy and security without permanently altering the standard workstation profile.

## Important Identity Rule

- `phoenix` and `emerald` are fixed desktop systems and must **NOT** have `secure-travel` enabled.
- The module and aspect must be implemented and tested for evaluation consistency, but remain dormant/opt-in for future laptop leaves.

## Scope

1. Create `modules/nixos/specializations/secure-travel.nix` and `den/aspects/secure-travel.nix`:
   - Kernel sysctl hardening:
     - `kernel.kptr_restrict = 2;`
     - `kernel.dmesg_restrict = 1;`
     - `kernel.unprivileged_bpf_disabled = 1;`
     - `kernel.yama.ptrace_scope = 2;`
     - Network anti-spoofing / anti-redirect: `net.ipv4.conf.all.rp_filter = 1;`, `net.ipv4.conf.all.accept_redirects = 0;`, `net.ipv4.tcp_syncookies = 1;`.
   - NetworkManager MAC address randomization:
     - `networking.networkmanager.wifi.macAddress = "random";`
     - `networking.networkmanager.ethernet.macAddress = "random";`
   - Soft VPN kill-switch:
     - NetworkManager dispatcher script to send desktop alerts if the VPN tunnel (`proton0` / `tun0`) drops.
   - Attack surface reduction:
     - Disables Bluetooth on travel mode.
     - Disables binary compatibility shims (`nix-ld`, `nix-alien`).
   - Secure DNS:
     - Quad9 DNS-over-TLS with fallback.
2. Provide clean enable option `options.myModules.specializations.secureTravel.enable = lib.mkEnableOption "secure travel specialization";` (default `false`).
3. Keep disabled by default on all hosts.

## Validation

- Module evaluates cleanly without errors.
- Flake checks pass.
- Neither `phoenix` nor `emerald` has `secure-travel` active in their bootloader configurations unless explicitly opted in.
