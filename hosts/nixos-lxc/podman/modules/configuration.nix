{
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  networking.hostName = "podman";

  # Static IP configuration - adjust IP as needed
  systemd.network = {
    enable = true;
    wait-online.enable = true;
    networks."10-eth0" = {
      matchConfig.Name = "eth0";
      address = [ "10.10.11.84/16" ];
      routes = [
        { Gateway = "10.10.10.1"; }
      ];
      networkConfig = {
        DNS = [ "10.10.10.1" ];
        Domains = [ "deepwatercreature.com" ];
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  networking = {
    useDHCP = false;
    useHostResolvConf = false;
    nameservers = [ "10.10.10.1" ];
  };

  services.resolved.enable = true;

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

  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  systemd.mounts = [
    {
      what = "debugfs";
      where = "/sys/kernel/debug";
      enable = false;
    }
  ];

  system.stateVersion = "25.05";
}
