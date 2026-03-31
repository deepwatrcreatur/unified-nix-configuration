{ lib, inputs, ... }:
{
  imports = [
    ../gateway/configuration.nix
    inputs.disko.nixosModules.disko
    ./disko.nix
  ];

  home-manager.extraSpecialArgs.hostName = lib.mkForce "router";

  services.router-homelab.sshTarget = lib.mkForce "ssh router.deepwatercreature.com";

  boot.loader.grub.enable = lib.mkForce false;
  # gateway sets limine.enable = lib.mkForce false (priority 50); use mkOverride 49
  # to beat it without causing a same-priority conflict.
  boot.loader.limine.enable = lib.mkOverride 49 true;
  boot.loader.efi.canTouchEfiVariables = false;

  # Logs disk is on scsi1 (spinning disk), formatted by disko as disk-logs-logs.
  # router-log-storage handles the mount; disko only formats the partition.
  services.router-log-storage.device = lib.mkForce "/dev/disk/by-partlabel/disk-logs-logs";

  # I226-V dual-port NIC via PCI passthrough gets PCI-bus-derived names in the VM.
  # hostpci0 (0000:03:00.0) → enp1s0 (LAN), hostpci1 (0000:04:00.0) → enp2s0 (WAN).
  # Management virtio NIC retains ens18 (same as gateway).
  services.router-networking = {
    wan.device = lib.mkForce "enp2s0";
    routedInterfaces.lan.device = lib.mkForce "enp1s0";
  };

  services.router-optimizations.interfaces = {
    wan.device = lib.mkForce "enp2s0";
    lan.device = lib.mkForce "enp1s0";
  };

  services.router-firewall.extraInputRules = lib.mkForce ''
    iifname {"enp1s0"} tcp dport 5201 accept comment "iperf3 from LAN"
  '';
}
