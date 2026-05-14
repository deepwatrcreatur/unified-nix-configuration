{ ... }:
{ lib, ... }:
{
  # Temporary landing path for the existing Vaglio LXC.
  #
  # The live host is still on an older 26.05-era image that uses dhcpcd and
  # the legacy network-setup service. A direct switch from that state to the
  # standard homeserver-networking/systemd-networkd model currently hangs
  # mid-activation and can strand the guest without IPv4. Preserve the legacy
  # DHCP stack for one safe landing deploy, then migrate to networkd in a
  # follow-up once the host is on the repo's 25.11 baseline.
  networking.useNetworkd = lib.mkForce false;
  networking.useDHCP = lib.mkForce true;
  networking.useHostResolvConf = lib.mkForce false;
  networking.dhcpcd = {
    enable = lib.mkForce true;
    persistent = lib.mkForce true;
  };

  # The 26.05 -> 25.11 landing path currently wedges if switch-to-configuration
  # tries to stop the live D-Bus / networking / roundtable stack and then wait
  # for completion over the same bus connection. Keep these units in place for
  # the landing deploy, then remove these overrides once Vaglio is on the
  # stable 25.11 baseline and can be migrated cleanly.
  systemd.services.dbus-broker = {
    reloadIfChanged = lib.mkForce true;
    restartIfChanged = lib.mkForce false;
    stopIfChanged = lib.mkForce false;
  };
  systemd.services.dbus = {
    reloadIfChanged = lib.mkForce true;
    restartIfChanged = lib.mkForce false;
    stopIfChanged = lib.mkForce false;
  };
  systemd.services.logrotate-checkconf = {
    restartIfChanged = lib.mkForce false;
    stopIfChanged = lib.mkForce false;
  };
  systemd.services.network-setup.stopIfChanged = lib.mkForce false;
  systemd.services.resolvconf.stopIfChanged = lib.mkForce false;
  systemd.services.nscd = {
    restartIfChanged = lib.mkForce false;
    stopIfChanged = lib.mkForce false;
  };
  systemd.services.roundtable = {
    restartIfChanged = lib.mkForce false;
    stopIfChanged = lib.mkForce false;
  };
  systemd.services.systemd-tmpfiles-resetup = {
    restartIfChanged = lib.mkForce false;
    stopIfChanged = lib.mkForce false;
  };

  systemd.network.enable = lib.mkForce false;
  services.resolved.enable = lib.mkForce false;
}
