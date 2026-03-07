{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    ../../../../modules/nixos/networking.nix
    ../../../../modules/nixos
    ../../../../modules/nixos/services/iperf3.nix
    ../../lxc-systemd-suppressions.nix
  ];

  networking.hostName = "nixos_lxc";

  # Enable fish shell since it's used by users
  programs.fish.enable = true;

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
    settings.PasswordAuthentication = true;
  };

  users.users.root.password = "temp123";

  systemd.mounts = [
    {
      what = "debugfs";
      where = "/sys/kernel/debug";
      enable = false;
    }
  ];

  system.stateVersion = "25.05";
}
