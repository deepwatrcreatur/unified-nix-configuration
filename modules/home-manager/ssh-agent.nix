# modules/home-manager/ssh-agent.nix
#
# Standalone SSH auth agent — no gpg-agent dependency.
#
# Linux:  starts ssh-agent as a systemd user service (home-manager).
# Darwin: macOS Keychain handles the SSH agent natively; we just set
#         AddKeysToAgent + UseKeychain in ssh config so keys are loaded
#         on first use without a passphrase prompt every session.
{ config, lib, pkgs, ... }:
{
  # Linux: systemd user SSH agent
  services.ssh-agent.enable = lib.mkIf pkgs.stdenv.isLinux true;

  # Darwin: delegate to macOS Keychain agent
  programs.ssh.extraConfig = lib.mkIf pkgs.stdenv.isDarwin ''
    Host *
      AddKeysToAgent yes
      UseKeychain yes
  '';
}
