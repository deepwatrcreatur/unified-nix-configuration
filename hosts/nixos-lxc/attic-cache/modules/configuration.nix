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
  ];

  # Enable fish shell since users set it as default
  programs.fish.enable = true;

  # Enable OpenSSH
  services.openssh.enable = true;

  # Attic client configuration (using agenix for token)
  # The nix-attic-infra module is disabled since it requires sops-nix internally
  # Configure attic manually via the attic CLI using the token from agenix

  networking.hostName = "attic-cache";

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  security.wrappers.sudo.setuid = true;

  # Agenix secrets are defined in ./agenix.nix

  systemd.mounts = [
    {
      what = "debugfs";
      where = "/sys/kernel/debug";
      enable = false;
    }
  ];

  system.stateVersion = "25.05";
}
