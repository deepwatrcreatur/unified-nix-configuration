# LXC systemd suppressions for units that are not available/needed in containers
{ lib, ... }:
{
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];

  # Workaround for systemd 254+ in unprivileged LXC containers
  # Fixes 243/CREDENTIALS errors by clearing credential loading
  systemd.services.systemd-networkd.serviceConfig.LoadCredential = lib.mkForce [ "" ];
  systemd.services.systemd-networkd.serviceConfig.ImportCredential = lib.mkForce [ "" ];
  systemd.services.systemd-resolved.serviceConfig.LoadCredential = lib.mkForce [ "" ];
  systemd.services.systemd-resolved.serviceConfig.ImportCredential = lib.mkForce [ "" ];
}
