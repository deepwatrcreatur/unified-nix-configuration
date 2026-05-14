{
  name,
  primaryUser,
  extraGroups,
  ...
}:
{
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/nixos/common
  ];

  networking.hostName = name;

  host.type = "server";
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

  users.users.root.shell = pkgs.fish;

  users.users.${primaryUser} = {
    isNormalUser = true;
    inherit extraGroups;
    shell = pkgs.fish;
  };

  services.ssh-keys-manager.username = primaryUser;

  system.stateVersion = "25.05";
}
