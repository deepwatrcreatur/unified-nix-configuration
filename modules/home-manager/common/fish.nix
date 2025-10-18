# modules/home-manager/fish-shared.nix

{ config, pkgs, lib, ... }:

{
  programs.fish = {
    enable = true;
    shellAliases = {
      rename = "rename -n";
      rename-apply = "rename";
    };
    plugins = [
      { name = "fzf"; src = pkgs.fishPlugins.fzf; }
      { name = "z"; src = pkgs.fishPlugins.z; }
      { name = "puffer"; src = pkgs.fishPlugins.puffer; }
      { name = "autopair"; src = pkgs.fishPlugins.autopair; }
      { name = "grc"; src = pkgs.fishPlugins.grc; }
    ];

    # shellInit runs for ALL shells (login and non-login) - critical for SSH
    shellInit = ''
      # Ensure Nix paths are in PATH early for ALL sessions (especially SSH)
      fish_add_path --prepend --move ${config.home.homeDirectory}/.nix-profile/bin
      fish_add_path --prepend --move /nix/var/nix/profiles/default/bin
      fish_add_path --prepend --move /run/current-system/sw/bin
    '';

    interactiveShellInit = ''
      # Set GPG_TTY for all systems
      set -gx GPG_TTY (tty)

      # Set NH_FLAKE for nh helper
      set -gx NH_FLAKE "${config.home.homeDirectory}/unified-nix-configuration"
    '';
  };
}
