# den/aspects/service-netalertx.nix
# NetAlertX network presence scanner container stack aspect: container definition and port 20211.
{ ... }:
{ ... }:
{
  imports = [
    ../../hosts/nixos-lxc/podman/stacks/netalertx-stack.nix
  ];

  networking.firewall.allowedTCPPorts = [
    20211 # NetAlertX
  ];
}
