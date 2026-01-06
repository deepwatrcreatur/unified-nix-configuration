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
    # Include user terminfo directory for ghostty and other custom terminals
    # Paths: user terminfo, system terminfo, homebrew terminfo (macOS)
    TERMINFO_DIRS = "${config.home.homeDirectory}/.terminfo:/usr/share/terminfo:/opt/homebrew/share/terminfo";
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
    initExtra = lib.mkAfter ''
      # CRITICAL: Set TERM to safe default if empty (happens in non-interactive SSH)
      # This prevents TUI applications like opencode from failing with "invalid input message type" errors
      if [ -z "$TERM" ]; then
        export TERM=xterm-256color
        export COLORTERM=truecolor
      fi

      # Determinate nixd completion (if available)
      if command -v determinate-nixd &>/dev/null; then
        eval "$(determinate-nixd --nix-bin /nix/var/nix/profiles/default/bin completion bash)"
      fi
    '';
  };
  programs.nushell = {
    enable = true;
    extraConfig = '''';
  };
  programs.fish = {
    enable = true;
    shellInit = ''

      # Determinate nixd completion (if available)
      if command -v determinate-nixd &>/dev/null
        eval "$(determinate-nixd --nix-bin /nix/var/nix/profiles/default/bin completion fish)"
      end
    '';
  };

  # Add zsh configuration with determinate nixd completion
  programs.zsh = {
    enable = true;
    initContent = lib.mkAfter ''
      # CRITICAL: Set TERM to safe default if empty (happens in non-interactive SSH)
      # This prevents TUI applications like opencode from failing with "invalid input message type" errors
      if [ -z "$TERM" ]; then
        export TERM=xterm-256color
        export COLORTERM=truecolor
      fi

      # Determinate nixd completion (if available)
      if command -v determinate-nixd &>/dev/null; then
        eval "$(determinate-nixd --nix-bin /nix/var/nix/profiles/default/bin completion zsh)"
      fi
    '';
  };
}
