{ config, ... }:

{
  programs.nushell = {
    enable = true;
    configFile.text = builtins.readFile ./config.nu;
  };
}
