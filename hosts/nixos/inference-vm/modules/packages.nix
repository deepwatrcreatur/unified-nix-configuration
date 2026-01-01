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

  # System packages for inference VMs
  environment.systemPackages = with pkgs; [
    # Editors
    vim
    neovim
    helix

    # Terminal tools
    nushell
    bat
    fzf
    yazi
    tmux

    # System monitoring
    netdata
    btop

    # Network tools
    tailscale
    iperf3

    # Development tools
    git
    gh
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
