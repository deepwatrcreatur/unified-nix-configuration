# modules/nixos/deepwatrcreatur-ssh-identity.nix
# Deploys a stable SSH identity for the deepwatrcreatur user from agenix secrets
{
  config,
  lib,
  ...
}:
let
  cfg = config.my.deepwatrcreatur-ssh-identity;
  secretFile = ../../secrets-agenix/deepwatrcreatur-ssh-key.age;
in
{
  options.my.deepwatrcreatur-ssh-identity = {
    enable = lib.mkEnableOption "stable SSH identity for deepwatrcreatur";
  };

  config = lib.mkIf (cfg.enable && builtins.pathExists secretFile) {
    # Decrypt the SSH key via agenix
    age.secrets."deepwatrcreatur-ssh-key" = {
      file = secretFile;
      path = "/home/deepwatrcreatur/.ssh/id_ed25519";
      owner = "deepwatrcreatur";
      group = "users";
      mode = "0600";
    };

    # Ensure ~/.ssh exists with correct permissions
    systemd.tmpfiles.rules = [
      "d /home/deepwatrcreatur/.ssh 0700 deepwatrcreatur users -"
    ];

    # Generate public key from private key after decryption
    system.activationScripts.deepwatrcreaturSshPublicKey = {
      text = ''
        if [[ -f /home/deepwatrcreatur/.ssh/id_ed25519 ]]; then
          ${config.programs.ssh.package}/bin/ssh-keygen -y -f /home/deepwatrcreatur/.ssh/id_ed25519 > /home/deepwatrcreatur/.ssh/id_ed25519.pub 2>/dev/null || true
          chmod 644 /home/deepwatrcreatur/.ssh/id_ed25519.pub 2>/dev/null || true
        fi
      '';
      deps = [ "agenix" ];
    };
  };
}
