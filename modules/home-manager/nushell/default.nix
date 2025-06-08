{ config, pkgs, ... }:

{
  programs.nushell = {
    enable = true;

  aliases = {
      update = "just update";
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
