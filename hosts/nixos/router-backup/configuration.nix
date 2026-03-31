{ lib, inputs, ... }:
{
  imports = [
    ../gateway/configuration.nix
    inputs.disko.nixosModules.disko
    ./disko.nix
  ];

  home-manager.extraSpecialArgs.hostName = lib.mkForce "router-backup";

  services.router-homelab.sshTarget = lib.mkForce "ssh router-backup.deepwatercreature.com";

  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # Intel I219 dual-port NIC via PCI passthrough.
  # Interface names are PCI-bus-derived (enp<bus>s<slot>) — set these to
  # the actual names observed after first boot on the target cluster node.
  services.router-networking = {
    wan.device = lib.mkForce "enp2s0";
    routedInterfaces = {
      lan.device = lib.mkForce "enp3s0";
      # No management interface on backup router — disable by removing the
      # management entry inherited from gateway configuration.
      management = lib.mkForce { };
    };
  };

  services.router-optimizations.interfaces = {
    wan.device = lib.mkForce "enp2s0";
    lan.device = lib.mkForce "enp3s0";
    management = lib.mkForce { };
  };

  services.router-firewall.extraInputRules = lib.mkForce ''
    iifname {"enp3s0"} tcp dport 5201 accept comment "iperf3 from LAN"
  '';

  # No separate logs disk on backup router — log locally.
  services.router-log-storage.enable = lib.mkForce false;
}
