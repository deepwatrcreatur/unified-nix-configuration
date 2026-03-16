{
  config,
  pkgs,
  lib,
  ...
}:
let
  sshAuthSock = "$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh";
  shellSock = ''$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null || printf %s "$SSH_AUTH_SOCK")'';
  shouldAutoLoadKeys = config.home.username != "root";
  loadKeysSh = ''
    if command -v gpgconf >/dev/null 2>&1; then
      export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
    fi

    if ssh-add -l >/dev/null 2>&1; then
      :
    else
      for key in "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa"; do
        if [ -f "$key" ]; then
          ssh-add "$key" >/dev/null 2>&1 || true
        fi
      done
    fi
  '';
in
{
  config = lib.mkIf (config.services.gpg-agent.enable && config.services.gpg-agent.enableSshSupport) {
    home.sessionVariables.SSH_AUTH_SOCK = sshAuthSock;

    home.file.".local/bin/ssh-add-default-keys" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -eu
        ${loadKeysSh}
      '';
    };

    programs.bash.initExtra = lib.mkAfter (''
      export SSH_AUTH_SOCK=${shellSock}
    '' + lib.optionalString shouldAutoLoadKeys ''
      ${loadKeysSh}
    '');

    programs.zsh.initContent = lib.mkAfter (''
      export SSH_AUTH_SOCK=${shellSock}
    '' + lib.optionalString shouldAutoLoadKeys ''
      ${loadKeysSh}
    '');

    programs.fish.interactiveShellInit = lib.mkAfter (''
      if command -q gpgconf
        set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket | string trim)
      end
    '' + lib.optionalString shouldAutoLoadKeys ''
      if not ssh-add -l >/dev/null 2>&1
        for key in ~/.ssh/id_ed25519 ~/.ssh/id_rsa
          if test -f $key
            ssh-add $key >/dev/null 2>&1
          end
        end
      end
    '');

    programs.nushell.extraConfig = lib.mkAfter (''
      if ("${config.home.homeDirectory}/.nix-profile/bin/gpgconf" | path exists) {
        $env.SSH_AUTH_SOCK = (^${config.home.homeDirectory}/.nix-profile/bin/gpgconf --list-dirs agent-ssh-socket | str trim)
      } else if ("/run/current-system/sw/bin/gpgconf" | path exists) {
        $env.SSH_AUTH_SOCK = (^/run/current-system/sw/bin/gpgconf --list-dirs agent-ssh-socket | str trim)
      }
    '' + lib.optionalString shouldAutoLoadKeys ''
      if ((do { ssh-add -l } | complete | get exit_code) != 0) {
        for key in [$"($env.HOME)/.ssh/id_ed25519" $"($env.HOME)/.ssh/id_rsa"] {
          if ($key | path exists) {
            ssh-add $key | ignore
          }
        }
      }
    '');
  };
}
