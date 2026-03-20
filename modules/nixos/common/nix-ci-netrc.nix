# modules/nixos/common/nix-ci-netrc.nix
# Prepares the nix-ci.com netrc file for the Nix daemon.
# The cache substituter/key are in modules/common/nix-settings.nix.
# This module handles the NixOS-specific systemd service.
{ lib, ... }:

let
  secretPath = "/run/secrets/nix-ci-netrc";
  targetPath = "/run/nix/nix-ci-netrc";
in
{
  # Prepare the netrc file for the Nix daemon (runs before nix-daemon starts)
  systemd.services.nix-ci-netrc = {
    description = "Prepare nix-ci.com netrc for Nix daemon";
    wantedBy = [ "multi-user.target" ];
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
        touch "${targetPath}"
        chmod 0600 "${targetPath}"
      fi
    '';
  };

  # Ensure nix-daemon waits for the netrc file
  systemd.services.nix-daemon = {
    after = [ "nix-ci-netrc.service" ];
    wants = [ "nix-ci-netrc.service" ];
  };
}
