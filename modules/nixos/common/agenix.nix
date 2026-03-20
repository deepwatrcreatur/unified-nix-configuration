{
  config,
  lib,
  ...
}:

{
  my.agenix.machineIdentity = {
    enable = lib.mkDefault false;
  };

  # System-wide agenix configuration
  # Secrets are decrypted at boot and placed in /run/agenix/
  age.identityPaths = lib.mkIf (!config.my.agenix.machineIdentity.enable) [
    "/etc/ssh/ssh_host_ed25519_key"
  ];

  # nix-ci.com cache authentication
  # Secret will only decrypt on hosts that have their key in secrets.nix
  age.secrets."nix-ci-netrc" = {
    file = ../../../secrets-agenix/nix-ci-netrc.age;
    path = "/run/secrets/nix-ci-netrc";
    owner = "root";
    mode = "0400";
  };
}
