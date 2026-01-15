{
  modulesPath,
  ...
}:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    ../../../../modules/nixos/networking.nix
  ];

  networking.hostName = "ansible";

  # LXC containers don't have a stable block device for `fileSystems."/".device`.
  # NixOS grow-partition relies on that, so disable it here.
  boot.growPartition = false;

  boot.initrd.systemd.fido2.enable = false;

  system.stateVersion = "25.05";
}
