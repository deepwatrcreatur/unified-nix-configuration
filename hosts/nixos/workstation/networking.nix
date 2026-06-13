{ config, lib, pkgs, ... }:

{
  networking = {
    hostName = "workstation";
    networkmanager.enable = true;
    search = [ "deepwatercreature.com" ];

    # Firewall configuration
    firewall = {
      enable = true;
      allowedTCPPorts = [
        24800
        631
        5201
      ]; # Deskflow server and CUPS
    };

    # Tell NetworkManager to use systemd-resolved for DNS (gets from DHCP)
    networkmanager.dns = "systemd-resolved";
  };

  # This host is NetworkManager-managed, so the shared systemd-networkd module
  # should not gate activation on networkd wait-online here.
  systemd.network.enable = lib.mkForce false;
  systemd.network.wait-online.enable = lib.mkForce false;

  # Preserve the existing NetworkManager profile contents (including custom IPv4
  # addressing) but ensure IPv6 uses SLAAC with stable-privacy addresses.
  systemd.services.networkmanager-ens18-ipv6 = {
    description = "Ensure NetworkManager ens18 uses SLAAC IPv6";
    after = [ "NetworkManager.service" ];
    wants = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      method="$(${pkgs.networkmanager}/bin/nmcli -g ipv6.method connection show ens18 2>/dev/null || true)"
      addr_gen="$(${pkgs.networkmanager}/bin/nmcli -g ipv6.addr-gen-mode connection show ens18 2>/dev/null || true)"

      if [ -z "$method" ]; then
        echo "NetworkManager connection ens18 not found; skipping IPv6 profile adjustment."
        exit 0
      fi

      if [ "$method" != "auto" ] || [ "$addr_gen" != "stable-privacy" ]; then
        ${pkgs.networkmanager}/bin/nmcli connection modify ens18 \
          ipv6.method auto \
          ipv6.addr-gen-mode stable-privacy
      fi
    '';
  };

  # Enable Tailscale VPN
  services.tailscale.enable = true;
}
