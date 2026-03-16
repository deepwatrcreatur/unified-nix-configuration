{
  pkgs,
  lib,
  isDesktop ? false,
  ...
}:
let
  shellAliases = {
    neohtop = "NeoHtop";
  };
in
{
  config = lib.mkIf isDesktop {
    home.packages = [ pkgs.neohtop ];

    programs.bash.shellAliases = lib.mkMerge [ shellAliases ];
    programs.zsh.shellAliases = lib.mkMerge [ shellAliases ];
    programs.fish.shellAliases = lib.mkMerge [ shellAliases ];
  };
}
