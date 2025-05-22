# modules/nixos/services/iperf3.nix
{ config, lib, pkgs, ... }:

{
  systemd.services.iperf3 = {
    description = "iPerf3 Server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.iperf3}/bin/iperf3 --server --bind 0.0.0.0 --port 5201";
      Restart = "always";
      Type = "simple";
    };
  };
}
