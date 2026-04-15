# Memory Archive: -home-deepwatrcreatur-flakes / 2dcfe045

**Source**: `/home/deepwatrcreatur/.claude/projects/-home-deepwatrcreatur-flakes/2dcfe045-30eb-4196-a3dd-fe31b94c0172.jsonl`  
**Date**: 2026-03-19  
**Findings**: 1

---

## Finding 1 (score=2, role=user, ts=2026-03-16T23:06:39.492Z)

/run/wrappers/bin/sudo nixos-rebuild switch --flake /home/deepwatrcreatur/flakes/unified-nix-configuration#homeserver
building the system configuration...
evaluation warning: deepwatrcreatur profile: The option `programs.ssh.userKnownHostsFile' defined in `/nix/store/3qgag860nh93hrfm3swm9x95zg6jb17a-source/modules/home-manager/common/ssh-config.nix' has been renamed to `programs.ssh.matchBlocks.*.userKnownHostsFile'.
evaluation warning: deepwatrcreatur profile: `programs.ssh` default values will be removed in the future.
                    Consider setting `programs.ssh.enableDefaultConfig` to false,
                    and manually set the default values you want to keep at
                    `programs.ssh.matchBlocks."*"`.
evaluation warning: root profile: The option `programs.ssh.userKnownHostsFile' defined in `/nix/store/3qgag860nh93hrfm3swm9x95zg6jb17a-source/modules/home-manager/common/ssh-config.nix' has been renamed to `programs.ssh.matchBlocks.*.userKnownHostsFile'.
evaluation warning: root profile: `programs.ssh` default values will be removed in the future.
                    Consider setting `programs.ssh.enableDefaultConfig` to false,
                    and manually set the default values you want to keep at
                    `programs.ssh.matchBlocks."*"`.
error: hash mismatch in fixed-output derivation '/nix/store/rrjiyhp86s3in4g37g9yynkk7g99fds5-semaphore_2.17.26_linux_amd64.tar.gz.drv':
         specified: sha256-CgrBN6tJIT0B8/qG0h2+ijxBo5ZkcKKj72wFmOGzNrs=
            got:    sha256-kdq7yaFR8axKrWxcfCKkj02vLkN1C6tOioq6vFcrlIc=
error: Cannot build '/nix/store/inqxvprnfzipb03cy9a1xh2ih57a71hb-semaphore-2.17.26.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/pbarafgdgsnmajqfsz1wdiq5nny7y740-semaphore-2.17.26
error: Cannot build '/nix/store/9dg8j506zkb3anmzd7bydn904vhvz3av-system-path.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/4mbdsn9jbh4h1d8jivx37x389vp82mya-system-path
e

---
