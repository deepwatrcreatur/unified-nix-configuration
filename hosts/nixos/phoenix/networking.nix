{ config, lib, pkgs, ... }:

{
  networking = {
    hostName = "phoenix";
    networkmanager.enable = true;

    firewall = {
      enable = true;
      allowedTCPPorts = [
        24800
        631
        5201
      ];
    };

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

  # Ensure primary 10G SFP+ interface (MAC 24:8a:07:8d:66:86, IP 10.10.11.92) takes
  # route precedence over secondary onboard NICs that receive dynamic DHCP leases.
  systemd.services.networkmanager-primary-metric = {
    description = "Ensure primary 10G interface has highest route priority (metric 50)";
    after = [ "NetworkManager.service" ];
    wants = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      for conn in "$(${pkgs.networkmanager}/bin/nmcli -t -f UUID connection show 2>/dev/null)"; do
        id="$(${pkgs.networkmanager}/bin/nmcli -g connection.id connection show "$conn" 2>/dev/null || true)"
        if [ "$id" = "Ethernet connection 1" ]; then
          current_metric="$(${pkgs.networkmanager}/bin/nmcli -g ipv4.route-metric connection show "$conn" 2>/dev/null || true)"
          if [ "$current_metric" != "50" ]; then
            ${pkgs.networkmanager}/bin/nmcli connection modify "$conn" ipv4.route-metric 50
            ${pkgs.networkmanager}/bin/nmcli connection up "$conn" || true
          fi
        fi
      done
    '';
  };

  services.tailscale.enable = true;
}
