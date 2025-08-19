# modules/home-manager/common/packages.nix
{ config, pkgs, lib, ... }: {
  home.packages = with pkgs; [
    comma
    wget
    curl
    xh
    fastfetch
    nmap
    htop
    btop
    iperf3
    yamllint
    file
    lsd
    bat
    tmux
    neovim
    flow-control
    python3
    glow
    age
  ];
}
