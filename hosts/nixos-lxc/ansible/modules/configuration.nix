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

  boot.initrd.systemd.fido2.enable = false;

  system.stateVersion = "25.05";
}
