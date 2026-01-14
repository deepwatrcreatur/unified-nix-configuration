# users/deepwatrcreatur/hosts/workstation/distrobox.nix
{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.distrobox.fedora;
in
{
  options.programs.distrobox.fedora = {
    enable = mkEnableOption "Enable Fedora distrobox configuration";
  };

  config = mkIf cfg.enable {
    home.file.".config/distrobox/fedora.conf" = {
      text = ''
        [distrobox]
        # Make Home Manager symlinked dotfiles work inside the container
        additional_flags="--volume /nix:/nix:ro"

        # Expose the stable NixOS per-user profile symlink (HM packages live here)
        additional_flags="--volume /etc/profiles/per-user:/etc/profiles/per-user:ro"
        additional_flags="--volume /etc/static/profiles/per-user:/etc/static/profiles/per-user:ro"

        # Fallback PATH entries: keep Fedora/RPM tools first, but don't break your
        # muscle-memory commands if they're only available via Nix.
        additional_paths="/etc/profiles/per-user/\$USER/bin"
        additional_paths="/nix/var/nix/profiles/system/sw/bin"
        additional_paths="/nix/var/nix/profiles/default/bin"
      '';
    };

    # NOTE: Create container manually after login to avoid blocking activation
    # distrobox create fedora --image fedora:latest --pull --init-hooks "sudo dnf install -y fuse-libs gtk3 nss"
  };
}
