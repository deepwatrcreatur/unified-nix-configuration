{
  config,
  lib,
  ...
}:

let
  cfg = config.my.agenix.machineIdentity;
  defaultPath = "/var/lib/agenix/machine-identity";
in
{
  options.my.agenix.machineIdentity = {
    enable = lib.mkEnableOption "dedicated stable agenix machine identity";

    path = lib.mkOption {
      type = lib.types.str;
      default = defaultPath;
      description = "Private key path used by agenix for machine-scoped secret decryption.";
    };

    legacyHostKeyFallback = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Keep the SSH host key as a secondary agenix identity during migration.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.path != "/etc/ssh/ssh_host_ed25519_key";
        message = "Use a dedicated machine identity path for agenix instead of the host SSH key.";
      }
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/agenix 0700 root root -"
    ];

    age.identityPaths = [ cfg.path ] ++ lib.optionals cfg.legacyHostKeyFallback [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
