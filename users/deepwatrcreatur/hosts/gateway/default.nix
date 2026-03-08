{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Home manager configuration for gateway
  home-manager.users.deepwatrcreatur = {
    imports = [
      ./nix-darwin # Import darwin-specific config (for macOS consistency)
    ];

    home.packages = with pkgs; [
      # Common utilities
      git
      vim
      wget
      curl
      rsync
      htop
      neofetch

      # Network utilities
      nmap
      tcpdump
      iperf3

      # System monitoring
      neofetch
      glances

      # SSH tools
      mosh
    ];

    # Terminal configuration
    programs.fish = {
      enable = true;
      shellInit = ''
        set fish_greeting

        # Aliases
        alias ls='eza --icons=auto'
        alias ll='eza -l --icons=auto'
        alias la='eza -la --icons=auto'
        alias grep='rg'
        alias cat='bat'
      '';
    };

    # Editor configuration
    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
    };
  };
}
