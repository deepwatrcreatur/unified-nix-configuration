{
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  networking.hostName = "podman";

  # Use DHCP - static lease configured in Technitium
  networking.useDHCP = true;

  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = true;
    PermitRootLogin = "yes";
    X11Forwarding = false;
  };

  programs.fish.enable = true;

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
