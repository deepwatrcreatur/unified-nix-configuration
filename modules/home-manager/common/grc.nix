# modules/home-manager/common/grc.nix
# GRC (Generic Colouriser) configuration for colorizing common shell commands
{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Commands that grc can colorize
  # These are the most commonly used commands that benefit from colorization
  grcCommands = [
    "df"
    "diff"
    "dig"
    "du"
    "env"
    "fdisk"
    "findmnt"
    "free"
    "gcc"
    "g++"
    "id"
    "ifconfig"
    "ip"
    "iptables"
    "last"
    "lsattr"
    "lsblk"
    "lsmod"
    "lsof"
    "lspci"
    "make"
    "mount"
    "mtr"
    "netstat"
    "nmap"
    "ping"
    "ps"
    "ss"
    "stat"
    "sysctl"
    "systemctl"
    "traceroute"
    "ulimit"
    "uptime"
    "vmstat"
    "w"
    "who"
  ];

  # Generate aliases for bash/zsh/fish (simple string format)
  grcAliases = builtins.listToAttrs (map (cmd: {
    name = cmd;
    value = "grc --colour=auto ${cmd}";
  }) grcCommands);

  # Generate nushell aliases as attrset (requires ^ prefix for external commands)
  nushellGrcAliases = builtins.listToAttrs (map (cmd: {
    name = cmd;
    value = "^grc --colour=auto ${cmd}";
  }) grcCommands);

  # Generate nushell aliases as raw config text (for extraConfig)
  nushellGrcAliasesText = lib.concatMapStringsSep "\n" (cmd:
    "alias ${cmd} = ^grc --colour=auto ${cmd}"
  ) grcCommands;
in
{
  options.custom.grc = {
    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = grcAliases;
      description = "GRC aliases for bash/zsh/fish shells";
      readOnly = true;
    };
    nushellAliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = nushellGrcAliases;
      description = "GRC aliases for nushell (as attrset for shellAliases)";
      readOnly = true;
    };
    nushellAliasesText = lib.mkOption {
      type = lib.types.str;
      default = nushellGrcAliasesText;
      description = "GRC aliases for nushell (as raw text for extraConfig)";
      readOnly = true;
    };
  };

  config = {
    home.packages = with pkgs; [
      grc
    ];
  };
}
