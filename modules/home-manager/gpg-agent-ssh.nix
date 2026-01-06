{
  config,
  pkgs,
  lib,
  ...
}:

{
  # SSH-friendly GPG agent configuration
  # Uses pinentry-curses which works over SSH without display server
  # Suitable for remote hosts like inference-vm

  home.packages = with pkgs; [
    pinentry-curses # Terminal-based pinentry for SSH
  ];

  programs.gpg = {
    enable = true;
  };

  # Set GPG_TTY for terminal sessions
  programs.bash.initExtra = lib.mkAfter ''
    export GPG_TTY=$(tty 2>/dev/null || echo "unknown")
  '';

  programs.fish.shellInit = lib.mkAfter ''
    set -gx GPG_TTY (tty 2>/dev/null; or echo "unknown")
  '';

  programs.zsh.initContent = lib.mkAfter ''
    export GPG_TTY=$(tty 2>/dev/null || echo "unknown")
  '';

  programs.nushell.extraConfig = lib.mkAfter ''
    # Set GPG_TTY for Nushell
    $env.GPG_TTY = (tty 2>/dev/null | str trim) or "unknown"
  '';

  # GPG agent configuration with long cache TTL
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
    enableSshSupport = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    enableFishIntegration = true;

    # Cache passphrase for 8 hours (28800 seconds)
    # This allows agents to commit without re-prompting over SSH
    defaultCacheTtl = 28800;
    maxCacheTtl = 28800;

    # Allow loopback pinentry for agents that can't interact directly
    extraConfig = "allow-loopback-pinentry";
  };

  # Helper function to pre-cache GPG passphrase
  home.file.".local/bin/gpg-cache-passphrase" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Pre-cache GPG passphrase for session
      # Use before running agents that will make commits

      if [ -z "$GPG_TTY" ]; then
        export GPG_TTY=$(tty)
      fi

      echo "Caching GPG passphrase for session..."
      # This prompts for passphrase once and caches it for 8 hours
      ${pkgs.gnupg}/bin/gpg --sign --armor --detach-sign < /dev/null > /dev/null

      if [ $? -eq 0 ]; then
        echo "✓ Passphrase cached successfully"
        echo "Passphrase will be cached for 8 hours"
      else
        echo "✗ Failed to cache passphrase"
        exit 1
      fi
    '';
  };

  # Ensure ~/.local/bin is in PATH
  home.sessionPath = [ "$HOME/.local/bin" ];
}
