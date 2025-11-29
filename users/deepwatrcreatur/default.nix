{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../modules/home-manager/secrets-activation.nix
    ./sops.nix
    ./rbw.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/bitwarden-cli.nix
    ../../modules/home-manager
  ];

  programs.bitwarden-cli = {
    enable = true;
  };

  programs.rclone.enable = true;

  home.file.".config/rclone/filter.txt" = {
    source = ./rclone-filter.txt;
  };

  home.username = "deepwatrcreatur";

  home.packages = with pkgs; [
    go
    chezmoi
    stow
    mix2nix
  ];

  home.file.".gnupg/public-key.asc" = {
    source = ./gpg-public-key.asc;  # Remove toString, just use the path directly
  };
  services.secrets-activation = {
    enable = true;
    secretsPath = toString ./secrets;
    continueOnError = false;  # Be stricter for regular user
    enableBitwardenDecryption = false;  # Handled by sops-nix
    enableGpgKeyDecryption = true;
  };

  # On macOS, the sops-nix LaunchAgent fails with "Operation not permitted" due to nix store mount restrictions.
  # Instead, disable the LaunchAgent and run sops-install-secrets during home-manager activation.
  launchd.agents.sops-nix = lib.mkForce { enable = false; };
  
  home.activation.sopsInstallSecrets = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ "$OSTYPE" == "darwin"* ]]; then
      echo "Running sops-install-secrets to decrypt secrets..."
      export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
      
      # Try to find and run the sops-nix-user script if it exists
      sops_nix_user="${config.sops.package}/bin/sops-install-secrets"
      if [[ ! -x "$sops_nix_user" ]]; then
        # Look for it in the LaunchAgent directory or nix store
        for script in /nix/store/*/sops-nix-user /nix/store/*/sops-install-secrets; do
          if [[ -x "$script" ]]; then
            sops_nix_user="$script"
            break
          fi
        done
      fi
      
      if [[ -x "$sops_nix_user" ]]; then
        bash "$sops_nix_user" || true
        echo "sops-install-secrets completed"
      else
        echo "Warning: sops-install-secrets not found, secrets may not be decrypted"
      fi
    fi
  '';
}
