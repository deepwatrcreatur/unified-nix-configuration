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

  # Agenix identity for secrets (sops-nix removed)
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # Enable OpenSSH with password auth and root login (matching cache-build-server)
  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = true;
    PermitRootLogin = "yes";
    X11Forwarding = false;
  };

  networking.hostName = "rustdesk";

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  security.wrappers.sudo.setuid = true;

  systemd.mounts = [
    {
      what = "debugfs";
      where = "/sys/kernel/debug";
      enable = false;
    }
  ];

  system.stateVersion = "25.05";
}
