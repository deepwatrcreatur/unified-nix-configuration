{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  # User configuration
  users.users.deepwatrcreatur = {
    isNormalUser = true;
    description = "Anwer Khan";
    home = "/home/deepwatrcreatur";
    extraGroups = [
      "networkmanager"
      "wheel"
      # "ollama"  # Temporarily disabled
    ];
    packages = with pkgs; [ ];
    shell = pkgs.fish;
    # SSH keys managed via SOPS if needed
  };

  users.users.root.shell = pkgs.nushell;

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
