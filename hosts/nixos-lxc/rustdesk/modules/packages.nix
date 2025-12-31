{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../../../modules/nixos/utility-packages.nix
  ];

  # RustDesk-specific package
  environment.systemPackages = with pkgs; [
    rustdesk-server
  ];
}
