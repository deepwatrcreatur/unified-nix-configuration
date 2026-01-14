{ lib, ... }:
{
  home-manager.backupFileExtension = lib.mkDefault "bak";
}
