# den/aspects/service-homeassistant.nix
# Home Assistant smart home automation container stack aspect: container definition and port 8123.
{ ... }:
{ ... }:
{
  imports = [
    ../../hosts/nixos-lxc/podman/stacks/home-assistant-stack.nix
  ];

  networking.firewall.allowedTCPPorts = [
    8123 # Home Assistant
  ];
}
