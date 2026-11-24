{ config, inputs, lib, ... }:
{
  imports = [ inputs.nix-ci.nixosModules.x86_64-linux.worker ];

  # SECURITY: This secret is scoped to Emerald; the common agenix module is
  # imported by hosts that are not recipients of the worker key.
  age.secrets."nix-ci-worker-key" = {
    file = ../../../secrets-agenix/nix-ci-worker-key.age;
    path = "/run/secrets/nix-ci-worker-key";
    owner = "root";
    mode = "0400";
  };

  services.nix-ci.production.worker = {
    enable = true;
    workers.emerald-worker-1 = {
      # The safe module runs each tenant in a guest VM and wipes its disk
      # after every stop, so no build output or tenant state carries over.
      auto-wipe = true;
      worker-count = 1;

      # Keep the guest off the home LAN while allowing public cache/repo access.
      local-network = "10.10.0.0/16";

      virtualisation = {
        cores = 12;
        memorySize = 48 * 1024;
        diskSize = 256 * 1024;
        sharedDirectories.nix-ci-credentials = {
          source = "/run/credentials/nix-ci-production-worker-emerald-worker-1.service";
          target = "/secrets";
        };
      };

      # Only the worker authentication key enters the isolated guest.
      extraServiceConfig.LoadCredential = [
        "worker-private-key:/run/secrets/nix-ci-worker-key"
      ];

      extraCoordinatorServiceConfig.LoadCredential = [
        "worker-private-key:/secrets/worker-private-key"
      ];

      config = {
        name = "emerald-worker-1";
        leader = "https://api.nix-ci.com";
        private-key-file = "/run/credentials/nix-ci-production-coordinator.service/worker-private-key";
      };

      # Restart the worker if its encrypted key changes, without putting the
      # plaintext credential in a derivation.
      extraRestartTriggers = [
        (builtins.hashFile "sha256" ../../../secrets-agenix/nix-ci-worker-key.age)
      ];
    };
  };

  assertions = [
    {
      assertion = config.services.nix-ci.production.worker.workers."emerald-worker-1".auto-wipe;
      message = "The NixCI safe worker must wipe its VM disk between tenants.";
    }
    {
      assertion = config.services.nix-ci.production.worker.workers."emerald-worker-1".local-network == "10.10.0.0/16";
      message = "The NixCI safe worker must be blocked from the home LAN.";
    }
    {
      assertion = config.services.nix-ci.production.worker.workers."emerald-worker-1".config.private-key-file
        == "/run/credentials/nix-ci-production-coordinator.service/worker-private-key";
      message = "The NixCI worker key must be loaded through a systemd credential.";
    }
    {
      assertion = (config.services.nix-ci.production.worker.workers."emerald-worker-1".config.private-key or null) == null;
      message = "The NixCI worker private key must not be embedded in Nix configuration.";
    }
    {
      assertion = config.systemd.services."nix-ci-production-worker-emerald-worker-1".serviceConfig.LoadCredential
        == [ "worker-private-key:/run/secrets/nix-ci-worker-key" ];
      message = "The safe worker host service must load only the worker key.";
    }
    {
      assertion = config.services.nix-ci.production.worker.innerSystems."emerald-worker-1".config.systemd.services."nix-ci-production-coordinator".serviceConfig.LoadCredential
        == [ "worker-private-key:/secrets/worker-private-key" ];
      message = "The safe worker coordinator must re-load its key from the guest credential mount.";
    }
  ];
}
