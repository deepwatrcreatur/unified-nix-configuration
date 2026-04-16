# modules/home-manager/git-ssh-signing.nix
#
# Configures git to sign commits with the host's SSH key instead of GPG.
# Works identically on NixOS and darwin: no pinentry, no gpg-agent.
#
# Requires: ~/.ssh/id_ed25519 (or id_rsa) to exist on the host.
# GitHub: register the same key under Settings → SSH keys → Signing keys.
{ config, lib, ... }:
let
  email = config.programs.git.settings.user.email or "deepwatrcreatur@gmail.com";
  allowedSigners = "${config.xdg.configHome}/git/allowed_signers";
in
{
  programs.git.settings = {
    gpg.format = "ssh";
    commit.gpgsign = true;
    tag.gpgsign = true;
    "user".signingkey = "~/.ssh/id_ed25519.pub";
    "gpg.ssh".allowedSignersFile = allowedSigners;
  };

  # Write allowed_signers at activation time from the live public key.
  # This is needed for `git log --show-signature` to verify local commits.
  home.activation.writeGitAllowedSigners = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _pub="$HOME/.ssh/id_ed25519.pub"
    _out="${allowedSigners}"
    if [ -f "$_pub" ]; then
      mkdir -p "$(dirname "$_out")"
      printf '%s namespaces="git" %s\n' "${email}" "$(cat "$_pub")" > "$_out"
    fi
  '';
}
