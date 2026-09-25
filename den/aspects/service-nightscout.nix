# den/aspects/service-nightscout.nix
# Nightscout CGM container stack aspect: container definition and port 11337.
{ ... }:
{ ... }:
{
  imports = [
    ../../hosts/nixos-lxc/podman/stacks/nightscout-stack.nix
  ];

  networking.firewall.allowedTCPPorts = [
    11337 # Nightscout
  ];
}
