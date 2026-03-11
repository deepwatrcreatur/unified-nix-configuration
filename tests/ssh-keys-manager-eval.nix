{ lib ? import <nixpkgs/lib> }:

let
  # A mock of the options from the ssh-keys-manager flake
  mockOptions = {
    options.services.ssh-keys-manager = {
      enable = lib.mkEnableOption "ssh keys manager";
      keysDirectory = lib.mkOption { type = lib.types.path; };
      username = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
      enableDynamicKeys = lib.mkEnableOption "dynamic keys";
    };
  };

  # Test case 1: Username is null by default
  evalDefault = lib.evalModules {
    modules = [
      mockOptions
      {
        services.ssh-keys-manager = {
          enable = true;
          keysDirectory = ../ssh-keys;
          enableDynamicKeys = true;
        };
      }
    ];
  };

  # Test case 2: Username can be set
  evalWithUser = lib.evalModules {
    modules = [
      mockOptions
      {
        services.ssh-keys-manager = {
          enable = true;
          keysDirectory = ../ssh-keys;
          enableDynamicKeys = true;
          username = "deepwatrcreatur";
        };
      }
    ];
  };

in
lib.runTests {
  testDefaultUsernameIsNull = {
    expr = evalDefault.config.services.ssh-keys-manager.username;
    expected = null;
  };

  testUsernameIsSet = {
    expr = evalWithUser.config.services.ssh-keys-manager.username;
    expected = "deepwatrcreatur";
  };
}