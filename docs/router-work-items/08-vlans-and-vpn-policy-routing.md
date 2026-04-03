# VLANs And VPN Policy Routing

Status: `blocked`
Suggested branch: `feat/router-vlans-and-vpn-routing`
Priority: `medium`

## Goal

Add the next generation of router capabilities after the baseline router is
stable again.

## High-Value Use Cases

- dedicated SSID/VLAN for VPN egress
- per-device VPN routing
- future guest / IoT / segmented networks

## Why This Is Valuable

This gives you an appliance-grade improvement you actually want:

- one Wi-Fi network can exit normally
- one Wi-Fi network can exit through a VPN provider
- later, specific hosts can be policy-routed differently

## Lower-Value Use Cases

- per-domain geo-routing by DNS tricks

That is much more brittle and should not be the first design.

## Tasks

- add first-class VLAN modeling
- add policy-routing support for per-subnet and per-device VPN egress
- preserve management-plane independence while doing so
- keep consumer-router-style workflows in mind

## Validation

- at least one VLAN/subnet can be routed independently
- VPN-routed subnet does not affect primary LAN

## Do Not

- do not begin until router baseline stability is solid
- do not start with per-domain Facebook/Netflix routing hacks
