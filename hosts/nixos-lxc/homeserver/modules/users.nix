{
  pkgs,
  ...
}:
{
  # Login shell is bash; interactive sessions exec fish (see modules/nixos/fish-interactive-bash-login.nix)
  custom.fishInteractiveShell.users = [ "root" "deepwatrcreatur" ];

  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
