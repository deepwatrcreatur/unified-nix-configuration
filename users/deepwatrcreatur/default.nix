{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../modules/home-manager/secrets-activation.nix
    ./sops.nix
    ./rbw.nix
    ./env.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/bitwarden-cli.nix
    ../../modules/home-manager/rclone-scripts.nix
    ../../modules/home-manager
  ];

  programs.bitwarden-cli = {
    enable = true;
  };

  home.username = "deepwatrcreatur";

  home.packages = with pkgs; [
    go
    chezmoi
    stow
    mix2nix
  ];

  home.file.".gnupg/public-key.asc" = {
    source = ./gpg-public-key.asc; # Remove toString, just use the path directly
  };

  home.activation.mySopsActivation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
    export PATH="${lib.makeBinPath [ pkgs.sops ]}:$PATH"

    # Decrypt gpg-private-key
    mkdir -p "$HOME/.gnupg"
    sops -d "${toString ./secrets}/gpg-private-key.asc.enc" > "$HOME/.gnupg/private-key.asc"
    chmod 600 "$HOME/.gnupg/private-key.asc"

    # Decrypt github-token
    mkdir -p "$HOME/.config/git"
    sops -d "${toString ./secrets}/github-token.txt.enc" > "$HOME/.config/git/github-token"
    chmod 600 "$HOME/.config/git/github-token"

    # Decrypt rclone.conf
    mkdir -p "$HOME/.config/rclone"
    rm -f "$HOME/.config/rclone/rclone.conf"
    sops -d "${toString ./secrets}/rclone.conf.enc" > "$HOME/.config/rclone/rclone.conf"
    chmod 600 "$HOME/.config/rclone/rclone.conf"

    # Decrypt attic-client-token
    mkdir -p "$HOME/.config/sops"
    sops -d --input-type yaml --extract '["ATTIC_CLIENT_JWT_TOKEN"]' "${toString ../../secrets}/attic-client-token.yaml.enc" > "$HOME/.config/sops/attic-client-token"
    chmod 600 "$HOME/.config/sops/attic-client-token"
  '';
}
