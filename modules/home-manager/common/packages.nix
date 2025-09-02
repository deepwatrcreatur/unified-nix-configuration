# modules/home-manager/common/packages.nix
{ config, pkgs, lib, ... }: {
  home.packages = with pkgs; [
    age
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
    htop
    iperf3
    jq
    lsd
    neovim
    nmap
    ouch
    python3
    tmux
    wget
    xh
    yamllint
    yq
  ];
}
