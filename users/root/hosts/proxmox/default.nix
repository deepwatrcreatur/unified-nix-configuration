# users/root/hosts/proxmox.nix
{ config, pkgs, lib, ... }:

{
  imports = [
    ../.. # default config for root
    ./proxmox-shell-extra.nix
    ./justfile.nix
    ./nh.nix
    #../../../../modules/home-manager/env/standalone-hm.nix
    ../../../../modules/home-manager/gpg-cli.nix
    ../../../../modules/home-manager/git.nix
    ../../../../modules/home-manager/secrets-activation.nix
  ];

  # Add packages to base config for root user
  home.packages = with pkgs; [
    rsync
  ];

  # Configure programs
  programs.bash.enable = true;
  services.attic-client.enable = true;

  home.file.".justfile".source = ./justfile; # Directly link the justfile

  # Configure secrets activation
  services.secrets-activation = {
    enable = true;
    secretsPath = toString ../../../../secrets;
    continueOnError = true;  # Be more forgiving for root
    enableBitwardenDecryption = true;
    enableGpgKeyDecryption = true;
  };
  
  home.file.".gnupg/public-key.asc" = {
    source = ../../gpg-public-key.asc;
  };

  services.gpg-agent.enableSshSupport = lib.mkForce false;
}
