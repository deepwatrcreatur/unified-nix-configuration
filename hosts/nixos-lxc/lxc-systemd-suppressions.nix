# LXC systemd suppressions for units that are not available/needed in containers
{ ... }:
{
  systemd.suppressedSystemUnits = [
    "dev-mqueue.mount"
    "sys-kernel-debug.mount"
    "sys-fs-fuse-connections.mount"
  ];
}