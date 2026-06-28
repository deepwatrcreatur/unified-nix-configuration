{ ... }:
{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.nix-router-optimized.nixosModules.router-networking
    inputs.nix-router-optimized.nixosModules.router-firewall
    inputs.nix-router-optimized.nixosModules.router-dns-service
    inputs.nix-router-optimized.nixosModules.router-ddns
    inputs.nix-router-optimized.nixosModules.router-homelab
    inputs.nix-router-optimized.nixosModules.router-kea
    inputs.nix-router-optimized.nixosModules.router-log-storage
    inputs.nix-router-optimized.nixosModules.router-optimizations
    inputs.nix-router-optimized.nixosModules.router-tailscale
    inputs.nix-router-optimized.nixosModules.router-observability
    inputs.nix-router-optimized.nixosModules.router-network-security
    inputs.nix-router-optimized.nixosModules.router-vpn
    inputs.nix-router-optimized.nixosModules.router-ntp
    inputs.nix-router-optimized.nixosModules.router-nat64
    inputs.nix-router-optimized.nixosModules.router-dns64
    inputs.nix-router-optimized.nixosModules.router-sqm
    inputs.nix-router-optimized.nixosModules.router-mdns
    inputs.nix-router-optimized.nixosModules.router-upnp
    inputs.nix-router-optimized.nixosModules.router-bgp
    inputs.nix-router-optimized.nixosModules.router-ha
    inputs.nix-router-optimized.nixosModules.router-mwan
    ../../modules/nixos/common
    ../../modules/nixos/services/iperf3.nix
    ../../modules/nixos/keyboard-glitches.nix
    ../../modules/nixos/snap.nix
    ../../modules/nixos/router-dashboard-runtime-repair.nix
    ../../modules/activation-scripts
  ];
}
