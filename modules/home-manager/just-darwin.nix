# modules/home-manager/just-darwin.nix - macOS-specific Justfile commands
{ pkgs, lib, config, ... }:
let
  hostname = config.networking.hostName;
in
{
  programs.just.settings = {
    # macOS-specific commands
    [group "darwin"]
    darwin = {
      docs = "macOS system operations";
    };

    # Your preserved recipes with important features
    update = {
      docs = "Update macOS system using darwin-rebuild";
      command = "ulimit -n 65536; sudo /nix/var/nix/profiles/system/sw/bin/darwin-rebuild switch --flake $NH_FLAKE#{{hostname}}";
    };

    "nh-update" = {
      docs = "Update macOS system using nh helper";
      command = "nh darwin switch";
    };

    # Additional macOS commands
    "build:darwin" = {
      docs = "Build macOS system without switching";
      command = "ulimit -n 65536; sudo /nix/var/nix/profiles/system/sw/bin/darwin-rebuild build --flake $NH_FLAKE#{{hostname}}";
    };

    "test:darwin" = {
      docs = "Test macOS configuration";
      command = "ulimit -n 65536; sudo /nix/var/nix/profiles/system/sw/bin/darwin-rebuild test --flake $NH_FLAKE#{{hostname}}";
    };

    # macOS-specific helpers
    "darwin:version" = {
      docs = "Show macOS version";
      command = "sw_vers";
    };

    "darwin:apps" = {
      docs = "Show installed Nix apps";
      command = "ls /nix/var/nix/profiles/per-user/*/profile/Applications";
    };

    # System management
    "system:gc" = {
      docs = "Garbage collect Nix store";
      command = "nix-collect-garbage -d";
    };

    "system:optimize" = {
      docs = "Optimize Nix store";
      command = "nix-store --optimise";
    };

    # macOS-specific utilities
    "macos:reload" = {
      docs = "Reload macOS launch services";
      command = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user";
    };

    "macos:clean" = {
      docs = "Clean macOS caches";
      command = "sudo rm -rf /Library/Caches/* && rm -rf ~/Library/Caches/*";
    };

    # Quick aliases
    switch = {
      docs = "Quick switch (alias for update)";
      command = "just update";
    };

    test = {
      docs = "Quick test (alias for test:darwin)";
      command = "just test:darwin";
    };
  };
}