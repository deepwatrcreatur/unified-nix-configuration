# modules/nixos/services/iperf3.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.services.iperf3;
in
{
  options.host.services.iperf3 = {
    enable = lib.mkEnableOption "LAN-bound iperf3 server";

    bindProbeAddress = lib.mkOption {
      type = lib.types.str;
      default = "10.10.10.1";
      description = "Address used to discover the LAN source IP for iperf3 binding.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = lib.mkIf config.networking.firewall.enable [ 5201 ];

    systemd.services.iperf3 = {
      description = "iPerf3 Server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "exec";
        Restart = "always";
        RestartSec = 2;
        ExecStart = pkgs.writeShellScript "iperf3-lan-server" ''
          set -euo pipefail

          bind_ip="$(${pkgs.iproute2}/bin/ip -4 route get ${cfg.bindProbeAddress} | ${pkgs.gawk}/bin/awk '{
            for (i = 1; i <= NF; i++) {
              if ($i == "src") {
                print $(i + 1)
                exit
              }
            }
          }')"

          if [ -z "$bind_ip" ]; then
            echo "Failed to determine LAN bind address for iperf3" >&2
            exit 1
          fi

          exec ${pkgs.iperf3}/bin/iperf3 --server --bind "$bind_ip" --port 5201
        '';
      };
    };
  };
}
