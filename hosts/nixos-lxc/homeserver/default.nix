{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./configuration.nix
    ./cloudflare-ddns.nix
    ./home-manager-users.nix
    ./influxdb.nix
    ./kasa-collector.nix
    # ./nginx-proxy-manager.nix  # Moved to gateway
    ./packages.nix
    ./podman.nix
    ./rsync.nix
    ./agenix.nix
    ./tplink-energy-monitor.nix
    ./users.nix
    ./nix-settings.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.05";
}
