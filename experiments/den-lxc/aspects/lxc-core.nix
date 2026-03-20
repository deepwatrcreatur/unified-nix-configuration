{
  name,
  primaryUser,
  extraGroups,
  ...
}:
{
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    ../../../modules/nixos/common
    ../../../modules/nixos/attic-client.nix
    ../../../modules/nixos/nix-daemon-user-ssh.nix
  ];

  networking.hostName = name;

  host.type = "lxc";
  host.networking.enableTailscale = false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
      X11Forwarding = false;
    };
  };

  programs.fish.enable = true;

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
  security.wrappers.sudo.setuid = true;

  systemd.mounts = [
    {
      what = "debugfs";
      where = "/sys/kernel/debug";
      enable = false;
    }
  ];

  users.users.root.shell = pkgs.fish;

  users.users.${primaryUser} = {
    isNormalUser = true;
    inherit extraGroups;
    shell = pkgs.fish;
  };

  services.ssh-keys-manager.username = primaryUser;

  system.stateVersion = "25.05";
}
