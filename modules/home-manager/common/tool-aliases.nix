# modules/home-manager/common/tool-aliases.nix
# Tool and utility aliases
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Tool and utility aliases
  toolAliases = {
    # Bat (cat replacement)
    bp = "bat --paging=never --plain";
    less = "bat --plain";

    # Just (command runner)
    update = "just update";
    nh-update = "just nh-update";

    # SSH
    ssh-nocheck = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ";

    # System tools
    rsync = "/run/current-system/sw/bin/rsync";

    # Tailspin
    tailspin = "tspin";

    # Atuin (shell history)
    asr = "atuin script run";
  };

  # Darwin-specific aliases
  darwinAliases = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    xcode = "open -a Xcode";
    gcc = lib.mkForce "/usr/bin/gcc";
    test-platform =
      "Platform detection: " + (if pkgs.stdenv.hostPlatform.isDarwin then "Darwin" else "Not Darwin");
  };

  # Prefer explicit wrappers via aliases (raw remains available)
  wrappedToolAliases =
    (lib.optionalAttrs (pkgs ? gh-fnox) { gh = "gh-fnox"; })
    // (lib.optionalAttrs (pkgs ? bw-fnox) { bw = "bw-fnox"; });
in
{
  options.custom.toolAliases = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable custom tool aliases";
    };

    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = toolAliases // wrappedToolAliases // darwinAliases;
      description = "Set of shell aliases for tools and utilities";
    };
  };

  # Note: Aliases are merged through shell-aliases.nix, not set directly here
  # to avoid conflicts with programs.bash.shellAliases
}
