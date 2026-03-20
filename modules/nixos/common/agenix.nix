{
  config,
  lib,
  ...
}:

let
  nixCiNetrcFile = ../../../secrets-agenix/nix-ci-netrc.age;
in
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
  # Secret only defined when the age file exists (allows merging before creating secret)
  age.secrets."nix-ci-netrc" = lib.mkIf (builtins.pathExists nixCiNetrcFile) {
    file = nixCiNetrcFile;
    path = "/run/secrets/nix-ci-netrc";
    owner = "root";
    mode = "0400";
  };
}
