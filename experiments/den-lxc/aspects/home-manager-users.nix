{
  primaryUser,
  primaryUserImports,
  rootImports,
  ...
}:
{
  inputs,
  lib,
  ...
}:
{
  systemd.services."home-manager-root".environment.NIX_REMOTE = "daemon";
  systemd.services."home-manager-${primaryUser}".environment.NIX_REMOTE = "daemon";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };

    users.root = {
      imports = [
        ../../../users/root
      ] ++ rootImports;

      home.username = "root";
      home.homeDirectory = "/root";
      home.stateVersion = lib.mkDefault "25.11";
      programs.home-manager.enable = true;
    };

    users.${primaryUser} = {
      imports = primaryUserImports;

      home.username = primaryUser;
      home.homeDirectory = "/home/${primaryUser}";
      home.stateVersion = lib.mkDefault "25.11";
      programs.home-manager.enable = true;
    };
  };
}
