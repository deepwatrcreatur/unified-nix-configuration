# modules/nixos/common/nix-ci-netrc.nix
# Prepares the nix-ci.com netrc file for the Nix daemon.
# The cache substituter/key are in modules/common/nix-settings.nix.
# This module handles the NixOS-specific systemd service and netrc-file setting.
{ lib, ... }:

let
  secretPath = "/run/secrets/nix-ci-netrc";
  targetPath = "/run/nix/nix-ci-netrc";
in
{
  # Configure nix to use the netrc file (NixOS-specific, not in common module)
  nix.settings.netrc-file = targetPath;

  # Prepare the netrc file for the Nix daemon (runs after agenix, before nix-daemon)
  systemd.services.nix-ci-netrc = {
    description = "Prepare nix-ci.com netrc for Nix daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "agenix.service" ];
    requires = [ "agenix.service" ];
    before = [ "nix-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail
      mkdir -p /run/nix

      # If secret exists, copy it; otherwise create empty file
      # (nix requires netrc-file to exist even if empty)
      if [[ -f "${secretPath}" && -r "${secretPath}" ]]; then
        umask 0077
        cp "${secretPath}" "${targetPath}"
        chmod 0600 "${targetPath}"
      else
        # Create empty file so nix doesn't error
        umask 0077
        touch "${targetPath}"
        chmod 0600 "${targetPath}"
      fi
    '';
  };

  # Ensure nix-daemon waits for the netrc file
  systemd.services.nix-daemon = {
    after = [ "nix-ci-netrc.service" ];
    requires = [ "nix-ci-netrc.service" ];
  };
}
