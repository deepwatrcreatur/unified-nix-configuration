# modules/home-manager/ssh-agent.nix
#
# Standalone SSH auth agent — no gpg-agent dependency.
#
# Linux:  starts ssh-agent as a systemd user service (home-manager) and keeps
#         the socket/key selection explicit for agent CLIs.
# Darwin: macOS Keychain handles the SSH agent natively; we just set
#         AddKeysToAgent + UseKeychain in ssh config so keys are loaded
#         on first use without a passphrase prompt every session.
{ lib, pkgs, ... }:
{
  # Linux: systemd user SSH agent.
  services.ssh-agent.enable = lib.mkIf pkgs.stdenv.isLinux true;

  # Give shells and agent CLIs a stable socket path instead of relying on
  # per-session discovery.
  home.sessionVariables = lib.mkIf pkgs.stdenv.isLinux {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
  };

  programs.ssh = {
    # Prefer the expected GitHub signing/transport key explicitly so agents can
    # discover it from config even before the agent has loaded any identities.
    settings = {
      "github.com" = {
        IdentitiesOnly = true;
        IdentityFile = "~/.ssh/id_ed25519";
        AddKeysToAgent = "yes";
      };
    };

    # Darwin: delegate to macOS Keychain agent.
    extraConfig = lib.mkIf pkgs.stdenv.isDarwin ''
      Host *
        AddKeysToAgent yes
        UseKeychain yes
    '';
  };
}
