{
  config,
  lib,
  pkgs,
  ...
}:

{
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
  i18n.extraLocales = [
    "en_US.UTF-8/UTF-8"
    "en_CA.UTF-8/UTF-8"
  ];
}
