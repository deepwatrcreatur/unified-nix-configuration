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

  system.stateVersion = "25.05";
}
