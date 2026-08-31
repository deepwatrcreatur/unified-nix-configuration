{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  deepwatrcreaturStableKey = lib.strings.trim (builtins.readFile ../../../../ssh-keys/deepwatrcreatur-stable-identity.pub);
  rootStableKey = lib.strings.trim (builtins.readFile ../../../../ssh-keys/root-stable-identity.pub);
in
{
  # User configuration
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    description = "Anwer Khan";
    home = "/home/deepwatrcreatur";
    hashedPasswordFile = config.age.secrets.user-password-deepwatrcreatur.path;
    extraGroups = [
      "networkmanager"
      "wheel"
      # "ollama"  # Temporarily disabled
    ];
    packages = with pkgs; [ ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      deepwatrcreaturStableKey
    ];
  };

  users.users.root = {
    shell = pkgs.nushell;
    hashedPasswordFile = config.age.secrets.user-password-root.path;
    openssh.authorizedKeys.keys = [
      rootStableKey
    ];
  };

  age.secrets.user-password-deepwatrcreatur.file = ../../../../secrets-agenix/user-password-deepwatrcreatur.age;
  age.secrets.user-password-root.file = ../../../../secrets-agenix/user-password-root.age;

  # Enable automatic login
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "deepwatrcreatur";

  # Home manager configuration using shared user configs
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };

    users.deepwatrcreatur = {
      imports = [
        ../../../../users/deepwatrcreatur/hosts/inference-vm
      ];
    };

    users.root = {
      imports = [
        ../../../../users/root/hosts/inference-vm
      ];
    };
  };
}
