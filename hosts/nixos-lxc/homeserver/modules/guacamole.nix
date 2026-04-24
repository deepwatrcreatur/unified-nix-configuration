{ config, lib, ... }:
{
  imports = [
    ../../../../modules/nixos/services/guacamole.nix
  ];

  age.secrets.guacamole-db-password = {
    file = ../../../../secrets-agenix/guacamole-db-password.age;
    owner = "root";
    mode = "0400";
  };

  services.guacamole-module = {
    enable = true;
    domain = "guacamole.deepwatercreature.com";
    dbPasswordFile = config.age.secrets.guacamole-db-password.path;
  };
}
