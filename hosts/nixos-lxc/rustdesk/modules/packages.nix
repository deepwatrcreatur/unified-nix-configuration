{
  config,
  lib,
  pkgs,
  ...
}:

{
  # RustDesk server packages
  environment.systemPackages = with pkgs; [
    # System tools
    vim
    git
    htop
    iotop
    lsof

    # Network tools
    curl
    wget
    netcat-openbsd

    # RustDesk server (included automatically via service)
    rustdesk-server
  ];
}
