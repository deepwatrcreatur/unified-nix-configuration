# modules/nixos/common/earlyoom.nix
# Protect systems from hard lockups and compositor crashes by killing
# heavy memory hogs before total RAM + swap exhaustion.
{ config, lib, pkgs, ... }:

{
  services.earlyoom = {
    enable = true;
    # Trigger when free memory falls below 5% and swap falls below 10%
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
    enableNotifications = true;
    # Avoid killing core desktop/compositor/system processes.
    # Prefer terminating known heavy memory consumers (browsers, VMs, background daemons).
    extraArgs = [
      "-g"
      "--avoid"
      "^(cosmic-comp|cosmic-session|greetd|systemd|wireplumber|pipewire|dbus-broker|dbus-daemon|sshd|Xwayland)$"
      "--prefer"
      "^(chrome|firefox|zen|electron|qemu|tailscaled)$"
    ];
  };
}
