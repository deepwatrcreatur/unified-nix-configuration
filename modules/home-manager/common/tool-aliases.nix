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
    j = "just-home";
    update = "update-system";
    nh-update = "nh-update-system";

    # SSH
    ssh-nocheck = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ";
    ssh-copy-id-dynamic = "ssh-copy-id -t .ssh/authorized_keys_dynamic";

    # System tools
    rsync = "/run/current-system/sw/bin/rsync";
    sudo = "/run/wrappers/bin/sudo";  # Use wrapped sudo with correct setuid permissions

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
    let
      ghAlias = if pkgs ? gh-fnox then { gh = "gh-fnox"; } else { };
      bwAlias = if pkgs ? bw-fnox then { bw = "bw-fnox"; } else { };
      atticAlias =
        if (pkgs ? attic-fnox) && !(config.programs.attic-client.enable or false)
        then { attic = "attic-fnox"; }
        else { };
      # When fnox is enabled, prefer the opencode-zai wrapper; keep opencode-raw
      # as an escape hatch to the unwrapped binary.
      opencodeFnoxAlias =
        if config.programs.fnox.enable or false
        then { opencode = "opencode-zai"; }
        else { };
    in
    ghAlias // bwAlias // atticAlias // opencodeFnoxAlias;
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
