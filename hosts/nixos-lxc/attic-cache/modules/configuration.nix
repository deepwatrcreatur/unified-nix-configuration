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

  # SOPS configuration for secrets management
  sops.age.keyFile = "/var/lib/sops/age/keys.txt";

  # Enable OpenSSH (also satisfies sops-nix requirement)
  services.openssh.enable = true;

  networking.hostName = "attic-cache";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.10.10.71";
      prefixLength = 16;
    }
  ];
  networking.defaultGateway = "10.10.10.1";
  networking.nameservers = [ "10.10.10.1" ];

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false;

  security.wrappers.sudo.setuid = true;

  # Agenix configuration
  age.secrets.attic-client-token = {
    file = ../../../../secrets-agenix/attic-client-token.age;
    owner = "root";
    mode = "0400";
  };

  systemd.mounts = [
    {
      what = "debugfs";
      where = "/sys/kernel/debug";
      enable = false;
    }
  ];

  system.stateVersion = "25.05";
}
