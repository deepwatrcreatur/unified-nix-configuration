{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    GPG_TTY = "(tty)";
  };
  home.sessionPath = [
    "/run/wrappers/bin" # NixOS security wrappers (sudo, etc.) must come first
    "${config.home.homeDirectory}/.nix-profile/bin"
    "/home/linuxbrew/.linuxbrew/bin"
    "/home/linuxbrew/.linuxbrew/sbin"
    "${config.home.homeDirectory}/.cargo/bin"
  ];

  # Set NH_FLAKE for bash specifically
  programs.bash = {
    sessionVariables = {
    };
    initExtra = ''
      # Determinate nixd completion
      eval "$(determinate-nixd --nix-bin /nix/var/nix/profiles/default/bin completion bash)"
    '';
  };
  programs.nushell = {
    enable = true;
    extraConfig = '''';
  };
  programs.fish = {
    enable = true;
    shellInit = ''

      # Determinate nixd completion
      eval "$(determinate-nixd --nix-bin /nix/var/nix/profiles/default/bin completion fish)"
    '';
  };

  # Add zsh configuration with determinate nixd completion
  programs.zsh = {
    enable = true;
    initContent = ''
      # Determinate nixd completion
      eval "$(determinate-nixd --nix-bin /nix/var/nix/profiles/default/bin completion zsh)"
    '';
  };
}
