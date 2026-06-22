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

  # Keep the primary LAN address DHCP-managed via the router reservation while
  # preserving the extra static management address on 192.168.100.0/24.
  systemd.services.networkmanager-ens18-profile = {
    description = "Ensure NetworkManager ens18 uses the intended workstation profile";
    after = [ "NetworkManager.service" ];
    wants = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ipv4_method="$(${pkgs.networkmanager}/bin/nmcli -g ipv4.method connection show ens18 2>/dev/null || true)"
      ipv4_addresses="$(${pkgs.networkmanager}/bin/nmcli -g ipv4.addresses connection show ens18 2>/dev/null || true)"
      ipv4_gateway="$(${pkgs.networkmanager}/bin/nmcli -g ipv4.gateway connection show ens18 2>/dev/null || true)"
      method="$(${pkgs.networkmanager}/bin/nmcli -g ipv6.method connection show ens18 2>/dev/null || true)"
      addr_gen="$(${pkgs.networkmanager}/bin/nmcli -g ipv6.addr-gen-mode connection show ens18 2>/dev/null || true)"

      if [ -z "$method" ]; then
        echo "NetworkManager connection ens18 not found; skipping profile adjustment."
        exit 0
      fi

      needs_ipv4_fix=0
      if [ "$ipv4_method" != "auto" ]; then
        needs_ipv4_fix=1
      fi
      if [ "$ipv4_addresses" != "192.168.100.98/24" ]; then
        needs_ipv4_fix=1
      fi
      if [ -n "$ipv4_gateway" ]; then
        needs_ipv4_fix=1
      fi

      if [ "$needs_ipv4_fix" -eq 1 ] || [ "$method" != "auto" ] || [ "$addr_gen" != "stable-privacy" ]; then
        ${pkgs.networkmanager}/bin/nmcli connection modify ens18 \
          ipv4.method auto \
          ipv4.addresses "192.168.100.98/24" \
          ipv4.gateway "" \
          ipv6.method auto \
          ipv6.addr-gen-mode stable-privacy
      fi
    '';
  };

  # Enable Tailscale VPN
  services.tailscale.enable = true;
}
