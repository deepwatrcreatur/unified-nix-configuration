# modules/home-manager/just-darwin.nix - macOS-specific Justfile commands
{ pkgs, lib, hostName, ... }:
{
  # Append macOS-specific commands to the base justfile
  home.file.".justfile".text = lib.mkAfter ''
    # macOS Commands
    # ==============

    # Update macOS system using darwin-rebuild
    update:
        ulimit -n 65536; sudo /nix/var/nix/profiles/system/sw/bin/darwin-rebuild switch --flake $NH_FLAKE#${hostName}

    # Update macOS system using nh helper
    nh-update:
        nh darwin switch

    # Build macOS system without switching
    build-darwin:
        ulimit -n 65536; sudo /nix/var/nix/profiles/system/sw/bin/darwin-rebuild build --flake $NH_FLAKE#${hostName}

    # Test macOS configuration
    test-darwin:
        ulimit -n 65536; sudo /nix/var/nix/profiles/system/sw/bin/darwin-rebuild test --flake $NH_FLAKE#${hostName}

    # Show macOS version
    darwin-version:
        sw_vers

    # Show installed Nix apps
    darwin-apps:
        ls /nix/var/nix/profiles/per-user/*/profile/Applications

    # Garbage collect Nix store
    system-gc:
        nix-collect-garbage -d

    # Optimize Nix store
    system-optimize:
        nix-store --optimise

    # Reload macOS launch services
    macos-reload:
        /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

    # Clean macOS caches
    macos-clean:
        sudo rm -rf /Library/Caches/* && rm -rf ~/Library/Caches/*

    # Quick switch (alias for update)
    switch: update
  '';
}
