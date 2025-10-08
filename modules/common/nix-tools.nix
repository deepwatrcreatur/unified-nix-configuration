{ config, pkgs, lib, inputs, ... }: {

  environment.systemPackages = with pkgs; [
    # cached-nix-shell  # Broken on macOS due to nokogiri compilation issues
    devenv
    lorri
    nix-output-monitor
    nix-tree
    nixfmt
    nvd
    statix
  ];
}
