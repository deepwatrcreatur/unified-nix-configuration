{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../../../modules/common/utility-packages.nix
  ];

  # RustDesk-specific package
  environment.systemPackages = with pkgs; [
    rustdesk-server
  ];
}
