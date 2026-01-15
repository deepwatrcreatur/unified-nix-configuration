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
    ../../../modules/nixos/services/iperf3.nix
    ../lxc-systemd-suppressions.nix
  ];

  # Enable fish shell since users set it as default
  programs.fish.enable = true;

  # Ensure SSH is enabled for SOPS
  services.openssh.enable = true;
  services.nginx-proxy-manager.enable = true;

  # Enable nix-ld for running dynamically linked executables (like homebrew packages)
  programs.nix-ld.enable = true;

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  systemd.mounts = [
    {
      what = "debugfs";
      where = "/sys/kernel/debug";
      enable = false;
    }
  ];

  boot.initrd.systemd.fido2.enable = false;

  # LXC containers don't have a stable block device for `fileSystems."/".device`.
  # NixOS grow-partition relies on that, so disable it here.
  boot.growPartition = false;

  system.stateVersion = "25.05";
}
