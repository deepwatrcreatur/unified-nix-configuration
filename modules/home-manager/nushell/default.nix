{ config, pkgs, ... }:

{
  programs.nushell = {
    enable = true;

  shellAliases = {
      update = "just update";
      nh-update = "just nh-update";
      ls = "lsd";
      ll = "lsd -l";
      la = "lsd -a";
      lla = "lsd -la";
      # The alias ".." must be quoted because it's not a valid identifier.
      ".." = "cd ..";
    };
  };

  programs.starship = {
    enableNushellIntegration = true; # This is the key for Nushell!
  };
}
