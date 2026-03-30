{ ... }:
{ inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.nix-router-optimized.nixosModules.router-networking
    inputs.nix-router-optimized.nixosModules.router-firewall
    inputs.nix-router-optimized.nixosModules.router-dns-service
    inputs.nix-router-optimized.nixosModules.router-homelab
    inputs.nix-router-optimized.nixosModules.router-log-storage
    inputs.nix-router-optimized.nixosModules.router-optimizations
    ../../modules/nixos/common
    ../../modules/nixos/services/iperf3.nix
    ../../modules/nixos/keyboard-glitches.nix
    ../../modules/nixos/snap.nix
    ../../modules/activation-scripts
    ../../hosts/nixos/router/configuration.nix
  ];
}
