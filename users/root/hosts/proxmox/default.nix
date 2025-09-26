# users/root/hosts/proxmox.nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ../.. # default config for root
    ./proxmox-fish-extra.nix
    # ./proxmox-justfile.nix # No longer needed
    ./nh.nix
    #../../../../modules/home-manager/env/standalone-hm.nix
    ../../../../modules/home-manager/gpg-cli.nix
    ../../../../modules/home-manager/git.nix
    ../../../../modules/home-manager/secrets-activation.nix
  ];

  # Add packages to base config for root user
  home.packages = with pkgs; [
    rsync
    nix
  ];

  # Configure programs
  programs.bash.enable = true;
  programs.attic-client.enable = true;

  home.file.".justfile".source = ./justfile; # Directly link the justfile

  # Configure secrets activation
  services.secrets-activation = {
    enable = true;
    secretsPath = toString ../../secrets;
    continueOnError = true;  # Be more forgiving for root
    enableBitwardenDecryption = true;
    enableGpgKeyDecryption = true;
  };
  
  home.file.".gnupg/public-key.asc" = {
    source = ../../gpg-public-key.asc;
  };
  home.file.".config/sops/.sops.yaml" = {
    source = "${toString ../../secrets}/sops.yaml";
    force = true;
  };
  home.file.".config/Bitwarden CLI/.keep".text = "";

}
