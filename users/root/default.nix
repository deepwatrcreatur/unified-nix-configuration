{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    # inputs.sops-nix.homeManagerModules.sops
    # ../../modules/home-manager/sops-root.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/gpg-cli.nix
    ../../modules/home-manager
  ];
  
  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
  ];
  # Allow root to manage Home Manager
  programs.home-manager.enable = true;

  home.activation.mySopsActivation = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
    export PATH="${lib.makeBinPath [ pkgs.sops ]}:$PATH"

    # Decrypt github-token
    mkdir -p "$HOME/.config/git"
    sops -d "${toString ./secrets}/github-token.txt.enc" > "$HOME/.config/git/github-token"
    chmod 600 "$HOME/.config/git/github-token"
  '';
}
