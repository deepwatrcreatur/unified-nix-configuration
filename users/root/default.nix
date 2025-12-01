{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/gpg-cli.nix
    ../../modules/home-manager
  ];

  home.username = "root";
  home.homeDirectory = "/root";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    sops
  ];
  # Allow root to manage Home Manager
  programs.home-manager.enable = true;

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  sops.gnupg.home = "${config.home.homeDirectory}/.gnupg";

  # This is the crucial line to prevent sops-nix from trying to restart a non-existent service
  home.activation.sops-nix = lib.mkForce "";

  home.file."${config.xdg.configHome}/sops/.sops.yaml" = {
    source = toString ../../.sops.yaml; # Link to the global sops.yaml
    force = true;
  };

  sops.secrets."github-token-root" = {
    sopsFile = toString ../../secrets/github-token.txt.enc;
    format = "binary";
  };

  sops.secrets."gpg-private-key" = {
    sopsFile = toString ../../secrets/gpg-private-key.asc.enc;
    format = "text";
  };

  home.activation.mySopsActivation = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Set SOPS_AGE_KEY_FILE and add sops and gpg to PATH for the script's execution context
    export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
    export PATH="${lib.makeBinPath [ pkgs.sops pkgs.gnupg ]}:$PATH"

    # Import the GPG private key after it has been decrypted by sops-nix
    # The path to the decrypted secret is available via config.sops.secrets."secret-name".path
    if [ -f "${config.sops.secrets."gpg-private-key".path}" ]; then
      echo "Attempting to import GPG private key..."
      gpg --batch --import "${config.sops.secrets."gpg-private-key".path}"
      if [ $? -eq 0 ]; then
        echo "GPG private key imported successfully."
        # Restart gpg-agent to ensure it picks up the new key
        gpgconf --kill gpg-agent
        gpg-connect-agent reloadagent /bye
        echo "gpg-agent restarted."
      else
        echo "ERROR: GPG private key import failed!"
      fi
    else
      echo "ERROR: GPG private key file not found or is empty: ${config.sops.secrets."gpg-private-key".path}"
    fi
  '';

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = lib.mkForce "root";
        email = lib.mkForce "deepwatrcreatur@gmail.com";
      };
      signing.signByDefault = lib.mkForce true; # This enables signing by default globally for Git.
    };
    signing = {
      key = "YOUR_GPG_KEY_ID"; # User needs to replace this
    };
  };

  home.file.".config/fish/conf.d/github-token.fish".text = ''
    set -x GITHUB_TOKEN (cat ${config.sops.secrets."github-token-root".path})
  '';
}