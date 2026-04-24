# modules/nixos/nix-daemon-user-ssh.nix
#
# Allow the Nix daemon to use a user's SSH agent socket for fetching
# git+ssh:// flake inputs during local rebuilds.
#
# This is required when flake.nix uses git+ssh:// URLs (e.g., to avoid
# GitHub API rate limits) and the host does local rebuilds.
#
# Requires: modules/home-manager/ssh-agent.nix enabled for the user
# (sets services.ssh-agent.enable = true, which creates the socket at
#  /run/user/<uid>/ssh-agent).
#
{ config, lib, ... }:

let
  cfg = config.myModules.nix-daemon-user-ssh;
in
{
  options.myModules.nix-daemon-user-ssh = {
    enable = lib.mkEnableOption "nix-daemon user SSH socket passthrough";

    userId = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "UID of the user whose SSH agent socket to use";
    };
  };

  config = lib.mkIf cfg.enable {
    # Point nix-daemon at the user's systemd ssh-agent socket
    systemd.services.nix-daemon.environment.SSH_AUTH_SOCK =
      "/run/user/${toString cfg.userId}/ssh-agent";
  };
}
