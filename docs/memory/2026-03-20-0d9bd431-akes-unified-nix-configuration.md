# Memory Archive: akes-unified-nix-configuration / 0d9bd431

**Source**: `/home/deepwatrcreatur/.claude/projects/-home-deepwatrcreatur-flakes-unified-nix-configuration/0d9bd431-0f52-4467-b8b7-17a9603185c3.jsonl`  
**Date**: 2026-03-20  
**Findings**: 1

---

## Finding 1 (score=2, role=user, ts=2026-03-16T12:31:35.833Z)

/run/wrappers/bin/sudo nixos-rebuild switch --flake $NH_FLAKE#workstation --option use-cgroups false
building the system configuration...
evaluation warning: buildRustPackage: `useFetchCargoVendor` is non‐optional and enabled by default as of 25.05, remove it
evaluation warning: 'system' has been renamed to/replaced by 'stdenv.hostPlatform.system'
failed to synthesize: failed to read /nix/store/7xkwxa9fh8hcm80y7n79knnqqgqja3iz-nixos-system-workstation-25.11.20260311.0590cd3/nixos-version: No such file or directory (os error 2)
Traceback (most recent call last):
  File "/nix/store/6rdck80010qhp9d2p5j1zn26mrnqiizx-systemd-boot/bin/systemd-boot", line 452, in <module>
    main()
    ~~~~^^
  File "/nix/store/6rdck80010qhp9d2p5j1zn26mrnqiizx-systemd-boot/bin/systemd-boot", line 435, in main
    install_bootloader(args)
    ~~~~~~~~~~~~~~~~~~^^^^^^
  File "/nix/store/6rdck80010qhp9d2p5j1zn26mrnqiizx-systemd-boot/bin/systemd-boot", line 383, in install_bootloader
    remove_old_entries(gens)
    ~~~~~~~~~~~~~~~~~~^^^^^^
  File "/nix/store/6rdck80010qhp9d2p5j1zn26mrnqiizx-systemd-boot/bin/systemd-boot", line 262, in remove_old_entries
    bootspec = get_bootspec(gen.profile, gen.generation)
  File "/nix/store/6rdck80010qhp9d2p5j1zn26mrnqiizx-systemd-boot/bin/systemd-boot", line 133, in get_bootspec
    boot_json_str = run(
                    ~~~^
        [
        ^
    ...<6 lines>...
        stdout=subprocess.PIPE,
        ^^^^^^^^^^^^^^^^^^^^^^^
    ).stdout
    ^
  File "/nix/store/6rdck80010qhp9d2p5j1zn26mrnqiizx-systemd-boot/bin/systemd-boot", line 58, in run
    return subprocess.run(cmd, check=True, text=True, stdout=stdout)
           ~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/nix/store/44rn0p64x92bnnh7cwn6x6ybvflybmvz-python3-3.13.12/lib/python3.13/subprocess.py", line 577, in run
    raise CalledProcessError(retcode, process.args,
                             output=stdout, stderr=stderr)
subprocess.CalledProcessError: Command '['/nix/st

---
