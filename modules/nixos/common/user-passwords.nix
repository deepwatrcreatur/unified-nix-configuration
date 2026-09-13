# modules/nixos/common/user-passwords.nix
# Fleet-wide declarative passwords for root and deepwatrcreatur via agenix.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  rootPasswordFile = ../../../secrets-agenix/user-password-root.age;
  deepwatrcreaturPasswordFile = ../../../secrets-agenix/user-password-deepwatrcreatur.age;
in
{
  age.secrets = {
    user-password-root = {
      file = lib.mkDefault rootPasswordFile;
    };
    user-password-deepwatrcreatur = {
      file = lib.mkDefault deepwatrcreaturPasswordFile;
    };
  };

  users.users.root = {
    hashedPasswordFile = lib.mkDefault config.age.secrets.user-password-root.path;
    initialHashedPassword = lib.mkDefault null;
  };

  users.users.deepwatrcreatur = {
    hashedPasswordFile = lib.mkDefault config.age.secrets.user-password-deepwatrcreatur.path;
  };

  # Activation script to ensure passwords in /etc/shadow are set on initial boot / activation
  # even when users.mutableUsers = true
  system.activationScripts.enforce-agenix-passwords = {
    text = ''
      for user in root deepwatrcreatur; do
        secret="/run/agenix/user-password-$user"
        if [ -s "$secret" ]; then
          hash=$(cat "$secret")
          current=$(grep "^$user:" /etc/shadow 2>/dev/null | cut -d: -f2)
          if [ "$current" = "!" ] || [ "$current" = "*" ] || [ -z "$current" ]; then
            echo "$user:$hash" | ${pkgs.shadow}/bin/chpasswd -e
          fi
        fi
      done
    '';
  };
}
