# modules/nixos/determinate-netrc-dir.nix
#
# Creates /nix/var/determinate with permissions allowing users to manage
# their netrc files for Determinate Nix / nix-ci.com authentication.
#
# This works across NixOS, Proxmox, and Ubuntu hosts using systemd-tmpfiles.
{ config, lib, ... }:

let
  cfg = config.services.determinate-netrc-dir;
in
{
  options.services.determinate-netrc-dir = {
    enable = lib.mkEnableOption "Determinate Nix netrc directory setup" // {
      default = true;
    };

    path = lib.mkOption {
      type = lib.types.str;
      default = "/nix/var/determinate";
      description = "Path to the Determinate Nix netrc directory";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Group that can write to the netrc directory";
    };
  };

  config = lib.mkIf cfg.enable {
    # Use systemd-tmpfiles to create and maintain the directory
    # This works on any systemd-based system (NixOS, Ubuntu, Proxmox)
    systemd.tmpfiles.rules = [
      # d = directory, path, mode, user, group, age, argument
      # Mode 0775 allows group write access
      "d ${cfg.path} 0775 root ${cfg.group} - -"
    ];

    # Heal permissions if the directory was created earlier with stricter mode.
    system.activationScripts.determinateNetrcDirPerms = ''
      if [ -d "${cfg.path}" ]; then
        chgrp ${cfg.group} "${cfg.path}" || true
        chmod 0775 "${cfg.path}" || true
      fi

      netrc_file="${cfg.path}/netrc"
      if [ -f "$netrc_file" ]; then
        chgrp ${cfg.group} "$netrc_file" || true
        chmod 0660 "$netrc_file" || true
      fi
    '';
  };
}
