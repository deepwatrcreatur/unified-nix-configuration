# modules/nixos/nix-daemon-user-ssh.nix
#
# Allow the Nix daemon to use a user's GPG SSH socket for fetching
# git+ssh:// flake inputs during local rebuilds.
#
# This is required when flake.nix uses git+ssh:// URLs (e.g., to avoid
# GitHub API rate limits) and the host does local rebuilds.
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
      description = "UID of the user whose GPG SSH socket to use";
    };
  };

  config = lib.mkIf cfg.enable {
    # Point nix-daemon at the user's GPG agent SSH socket
    systemd.services.nix-daemon.environment.SSH_AUTH_SOCK =
      "/run/user/${toString cfg.userId}/gnupg/S.gpg-agent.ssh";
  };
}
