{ config, lib, pkgs, ... }:

{
  # System packages for inference VMs
  environment.systemPackages = with pkgs; [
    # Editors
    vim
    neovim
    helix
    
    # Terminal tools
    ghostty
    kitty
    nushell
    bat
    fzf
    yazi
    tmux
    
    # System monitoring
    netdata
    htop
    btop
    
    # Network tools
    tailscale
    wget
    curl
    iperf3
    
    # Development tools
    git
    gitAndTools.gh
    elixir
    erlang
    tigerbeetle
    
    # System tools
    stow
    home-manager
    sops
    age
    ssh-to-age
    
    # Shell themes
    oh-my-posh
    starship
  ];

  # Shell initialization
  environment.interactiveShellInit = ''
    eval "$(oh-my-posh init bash --config ${pkgs.oh-my-posh}/share/oh-my-posh/themes/jandedobbeleer.omp.json)"
  '';
}