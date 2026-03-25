# modules/nixos/root-ssh-identity.nix
# Deploys a stable root SSH identity from agenix secrets
{
  config,
  lib,
  ...
}:
let
  cfg = config.my.root-ssh-identity;
  secretFile = ../../secrets-agenix/root-ssh-key.age;
in
{
  options.my.root-ssh-identity = {
    enable = lib.mkEnableOption "stable root SSH identity deployment";
  };

  config = lib.mkIf (cfg.enable && builtins.pathExists secretFile) {
    # Decrypt the root SSH key via agenix
    age.secrets."root-ssh-key" = {
      file = secretFile;
      path = "/root/.ssh/id_ed25519";
      owner = "root";
      group = "root";
      mode = "0600";
    };

    # Ensure /root/.ssh exists with correct permissions
    systemd.tmpfiles.rules = [
      "d /root/.ssh 0700 root root -"
    ];

    # Generate public key from private key after decryption
    system.activationScripts.rootSshPublicKey = {
      text = ''
        if [[ -f /root/.ssh/id_ed25519 ]]; then
          ${config.programs.ssh.package}/bin/ssh-keygen -y -f /root/.ssh/id_ed25519 > /root/.ssh/id_ed25519.pub 2>/dev/null || true
          chmod 644 /root/.ssh/id_ed25519.pub 2>/dev/null || true
        fi
      '';
      deps = [ "agenix" ];
    };
  };
}
