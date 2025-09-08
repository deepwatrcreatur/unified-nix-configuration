# modules/home-manager/common/packages.nix
{ config, pkgs, lib, ... }: {
  home.packages = with pkgs; [
    age
    bandwhich
    bottom
    btop
    comma
    curl
    dig
    dua
    dust
    fastfetch
    file
    flow-control
    glow
    gping
    grex
    htop
    iperf3
    jq
    lsd
    neovim
    nmap
    ouch
    python3
    sad
    sshs
    tmux
    wget
    xh
    yamllint
    yq
  ];
}
