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

  # Login shell is bash; interactive sessions exec fish (see modules/nixos/fish-interactive-bash-login.nix)
  custom.fishInteractiveShell.users = [ "root" primaryUser ];

  users.users.${primaryUser} = {
    isNormalUser = true;
    inherit extraGroups;
  };

  services.ssh-keys-manager.username = primaryUser;

  system.stateVersion = "25.05";
}
