# modules/home-manager/nushell/default.nix
{ config, pkgs, ... }:

{
  programs.nushell = {
    enable = true;

    # This is the key addition:
    # It adds the GPG_TTY setting to Nushell's environment config.
    envConfig = ''
      # Set GPG_TTY for GPG signing in the terminal
      $env.GPG_TTY = (tty)
    '';

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

  # This part remains the same, ensuring Starship is used for the prompt.
  programs.starship = {
    enableNushellIntegration = true;
  };
}
