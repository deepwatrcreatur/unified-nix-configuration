# den/aspects/service-gatus.nix
# Automated fleet status dashboard aspect (Gatus)
{ ... }:
{ lib, ... }:
{
  imports = [
    ../../modules/nixos/services/gatus-inventory.nix
  ];

  services.gatus-inventory = {
    enable = true;
    address = "0.0.0.0";
    openFirewall = true;
  };

  # When running inside an unprivileged Proxmox LXC container, DynamicUser=true
  # prevents opening raw ICMP sockets. Running as root in the container user namespace
  # retains raw socket capabilities for ICMP ping checks.
  systemd.services.gatus.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = lib.mkForce "root";
    Group = lib.mkForce "root";
  };
}
