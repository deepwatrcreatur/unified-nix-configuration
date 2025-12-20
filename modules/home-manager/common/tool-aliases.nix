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
    cat = "bat";
    less = "bat --plain";

    # Just (command runner)
    update = "just --justfile ~/.config/just/justfile update";
    nh-update = "just --justfile ~/.config/just/justfile nh-update";

    # SSH
    ssh-nocheck = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ";

    # System tools
    rsync = "/run/current-system/sw/bin/rsync";

    # Atuin (shell history)
    asr = "atuin script run";
  };

    # Darwin-specific aliases
  darwinAliases = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    xcode = "open -a Xcode";
    gcc = "/usr/bin/gcc";
    test-platform = "Platform detection: " + (if pkgs.stdenv.hostPlatform.isDarwin then "Darwin" else "Not Darwin");
  };
in
{
  options.custom.toolAliases = {
    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = toolAliases // darwinAliases;
      description = "Tool and utility aliases";
      readOnly = true;
    };
  };

  
}
