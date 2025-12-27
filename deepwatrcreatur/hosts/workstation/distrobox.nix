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
        additional_paths = /etc/profiles/per-user/\$USER/bin
      '';
    };

    # NOTE: Create container manually after login to avoid blocking activation
    # distrobox create fedora --image fedora:latest --pull --init-hooks "sudo dnf install -y fuse-libs gtk3 nss"
  };
}
