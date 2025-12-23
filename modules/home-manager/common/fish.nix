# modules/home-manager/fish-shared.nix

{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.fish = {
    enable = true;
    shellAliases = {
      rename = "rename -n";
      rename-apply = "rename";
    };
    plugins = [
      {
        name = "fzf";
        src = pkgs.fishPlugins.fzf;
      }
      {
        name = "z";
        src = pkgs.fishPlugins.z;
      }
      {
        name = "puffer";
        src = pkgs.fishPlugins.puffer;
      }
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair;
      }
      {
        name = "grc";
        src = pkgs.fishPlugins.grc;
      }
    ];

    # shellInit runs for ALL shells (login and non-login) - critical for SSH
    shellInit = lib.mkAfter ''
      # Set TERMINFO_DIRS early for SSH sessions with custom terminals (ghostty, kitty)
      # This must be set before tmux or other programs try to use terminfo
      set -gx TERMINFO_DIRS "${config.home.homeDirectory}/.terminfo:/usr/share/terminfo"
      
      # Prioritize Homebrew binaries
      fish_add_path --prepend --move /home/linuxbrew/.linuxbrew/bin

      # Ensure Nix paths are in PATH early for ALL sessions (especially SSH)
      fish_add_path --prepend --move ${config.home.homeDirectory}/.nix-profile/bin
      fish_add_path --prepend --move /nix/var/nix/profiles/default/bin
      fish_add_path --prepend --move /run/current-system/sw/bin
    '';

    interactiveShellInit = lib.mkAfter ''
      # Set GPG_TTY for all systems
      set -gx GPG_TTY (tty)

      # Set NH_FLAKE for nh helper
      set -gx NH_FLAKE "${config.home.homeDirectory}/unified-nix-configuration"

      # Ensure /run/wrappers/bin is at the front of PATH for NixOS security wrappers
      if test -d /run/wrappers/bin
        set -gx PATH /run/wrappers/bin $PATH
      end
    '';

    functions = {
      kilocode = ''
        # Launch KiloCode with proper terminal settings for Ghostty compatibility
        set -gx TERM xterm-256color
        set -gx COLORTERM truecolor
        command kilocode $argv
      '';
    };
  };
}
