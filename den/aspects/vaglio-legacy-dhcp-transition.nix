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

  systemd.network.enable = lib.mkForce false;
  services.resolved.enable = lib.mkForce false;
}
