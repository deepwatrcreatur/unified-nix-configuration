{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../../default.nix
  ];

  # Minimal home environment for RustDesk server management
  # Inherits: git, bitwarden-cli, rclone, sops, and full home-manager setup from parent
  #
  # Disabled heavy dev tools not needed on server:
  # - helix with language servers (pulls in erlang, elixir, etc. for development)
  # - yazelix/yazelix-upstream (full IDE experience not needed)
  # These are available on development machines: macminim4, workstation, inference-vm

  home.packages = with pkgs; [
    # RustDesk server management
    just
  ];

  # Disable helix editor - too heavy for a server with all language servers
  programs.helix.enable = lib.mkForce false;

  home.stateVersion = "25.11";
}
