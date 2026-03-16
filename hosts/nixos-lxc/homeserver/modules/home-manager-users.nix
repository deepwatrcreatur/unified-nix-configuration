{
  ...
}:
{
  systemd.services."home-manager-root".environment.NIX_REMOTE = "daemon";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.root = {
      imports = [
        ../../../../users/root
      ];
    };

    users.deepwatrcreatur = {
      imports = [
        ../../../../users/deepwatrcreatur/hosts/homeserver
      ];
    };
  };
}
