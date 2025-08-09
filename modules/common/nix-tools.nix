{ config, pkgs, lib, inputs, ... }: {

  environment.systemPackages = with pkgs; [
    cached-nix-shell
    devenv
    lorri
    nix-output-monitor
    nix-tree
    nixfmt
    nvd
    statix    
  ];
}
