{
  config,
  lib,
  pkgs,
  ...
}:

{
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
}
