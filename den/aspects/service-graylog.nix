# den/aspects/service-graylog.nix
# Graylog centralized syslog & observability container stack aspect: UI/API port 9000, syslog UDP 1514.
{ ... }:
{ ... }:
{
  imports = [
    ../../hosts/nixos-lxc/podman/stacks/graylog-stack.nix
  ];

  networking.firewall = {
    allowedTCPPorts = [
      9000 # Graylog Web UI / API
    ];
    allowedUDPPorts = [
      1514 # Graylog Syslog UDP
    ];
  };
}
