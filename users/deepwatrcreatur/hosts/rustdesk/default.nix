{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ../../default.nix
  ];

  # Minimal home environment for RustDesk server management
  # Inherits: git, bitwarden-cli, rclone, sops, and full home-manager setup from parent

  home.packages = with pkgs; [
    # RustDesk server management
    just
  ];

  home.stateVersion = "25.11";
}
