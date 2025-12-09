{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    ../.. # Import default root config
  ];

  # Root-specific packages for inference node administration
  home.packages = with pkgs; [

    # System administration
    lsof
    strace

    # Service management helpers
    systemctl-tui
  ];

  programs.attic-client.enable = true;

}
