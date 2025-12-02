{ config, pkgs, lib, inputs, ... }:
let
  gpgEncryptedFilePath = ./secrets/gpg-private-key.asc.enc;
in
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  home.packages = with pkgs; [
    sops
  ];

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  sops.gnupg.home = "${config.home.homeDirectory}/.gnupg";

  home.activation.sops-nix = lib.mkForce "";

  home.file."${config.xdg.configHome}/sops/.sops.yaml" = {
    source = ./secrets/sops.yaml; # Link to the user-specific sops.yaml
    force = true;
  };

  sops.secrets."github-token-root" = {
    sopsFile = ./secrets/github-token.txt.enc;
    format = "binary";
  };

  home.activation.mySopsActivation = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Set SOPS_AGE_KEY_FILE and add sops and gpg to PATH for the script's execution context
    export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
    export PATH="${lib.makeBinPath [ pkgs.sops pkgs.gnupg ]}:$PATH"

    # --- Manual GPG Private Key Decryption and Import ---
    GPG_ENCRYPTED_FILE_PATH="${gpgEncryptedFilePath}" # Nix will interpolate the correct path here
    GPG_DEC_FILE_PATH="$HOME/.gnupg/private-key.asc" # Desired output path for manual decryption
    
    mkdir -p "$HOME/.gnupg" # Ensure directory exists
    
    # Perform manual decryption using sops -d, explicitly passing the AGE private key
    sops -d --age "$(cat "$SOPS_AGE_KEY_FILE")" "$GPG_ENCRYPTED_FILE_PATH" > "$GPG_DEC_FILE_PATH"
    
    # Attempt to import GPG private key from $GPG_DEC_FILE_PATH
    gpg --batch --import "$GPG_DEC_FILE_PATH"
    
    # Restart gpg-agent to ensure it picks up the new key
    gpgconf --kill gpg-agent
    gpg-connect-agent reloadagent /bye
  '';

  home.file.".config/fish/conf.d/github-token.fish".text = ''
    set -x GITHUB_TOKEN (cat ${config.sops.secrets."github-token-root".path})
  '';
}