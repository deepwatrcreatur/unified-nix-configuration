{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [ inputs.nix-coding-agents.homeManagerModules.default ];

  config = {
    programs.coding-agents.enable = lib.mkDefault true;
  };
}
