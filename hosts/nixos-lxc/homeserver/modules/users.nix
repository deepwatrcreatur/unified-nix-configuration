{
  pkgs,
  ...
}:
{
  users.users.root.shell = pkgs.fish;

  users.users.deepwatrcreatur = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;
  };
}
