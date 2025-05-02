{ modulesPath, pkgs, ... }:

{
  imports = [
    # Include the default lxc configuration.
    "${modulesPath}/virtualisation/lxc-container.nix"

  ];

  environment.shells = with pkgs; [ bashInteractive ];
  environment.systemPackages = with pkgs; [ busybox coreutils ];
  system.activationScripts.binBashSymlink.text = ''
    ln -sf /run/current-system/sw/bin/bash /bin/bash
    ln -sf /run/current-system/sw/bin/bash /bin/sh
  '';
  environment.extraInit = ''
    export PATH=/run/current-system/sw/bin:/usr/bin:/bin
  '';

  #networking.hostName = "nixos-lxc";
  networking = {
    hostName = "nixos-lxc";
    dhcpcd.enable = false;
    useDHCP = false;
    useHostResolvConf = false;
  };

  systemd.network = {
    enable = true;
    networks."50-eth0" = {
      matchConfig.Name = "eth0";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  system.stateVersion = "25.05"; # Did you read the comment?
}
