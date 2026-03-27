{ lib, pkgs }:

let
  # A minimal stub for the inputs.ssh-keys-manager.nixosModules.default
  # that only provides the options needed for the test to evaluate successfully
  mockFlakeModule = {
    options.services.ssh-keys-manager = {
      enable = lib.mkEnableOption "ssh keys manager";
      keysDirectory = lib.mkOption { type = lib.types.path; };
      username = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
      enableDynamicKeys = lib.mkEnableOption "dynamic keys";
    };
  };

  # Provide the inputs structure as it would be passed by the flake
  mockInputs = {
    ssh-keys-manager = {
      nixosModules = {
        default = mockFlakeModule;
        ssh-known-hosts = { };
      };
    };
  };

  # Dummy modules needed to satisfy the common module's references to base NixOS options
  dummyModules = [
    {
      options.users.users = lib.mkOption {
        type = lib.types.attrsOf lib.types.attrs;
        default = {};
      };
      options.programs.ssh-known-hosts-manager = {
        enable = lib.mkEnableOption "ssh known hosts manager";
        keysDirectory = lib.mkOption { type = lib.types.path; };
        sshConfigFile = lib.mkOption { type = lib.types.path; };
      };
      options.services.openssh.enable = lib.mkEnableOption "ssh";
      options.services.openssh.extraConfig = lib.mkOption { type = lib.types.str; default = ""; };
      options.systemd.tmpfiles.rules = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
    }
  ];

  # Test case 1: Username is null by default
  evalDefault = lib.evalModules {
    specialArgs = {
      inherit pkgs;
      inputs = mockInputs;
    };
    modules = dummyModules ++ [
      ../modules/nixos/common/ssh-keys.nix
    ];
  };

  # Test case 2: Username can be set
  evalWithUser = lib.evalModules {
    specialArgs = {
      inherit pkgs;
      inputs = mockInputs;
    };
    modules = dummyModules ++ [
      ../modules/nixos/common/ssh-keys.nix
      {
        services.ssh-keys-manager.username = "deepwatrcreatur";
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
