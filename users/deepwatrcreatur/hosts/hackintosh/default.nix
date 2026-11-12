{
  imports = [
    ../../default.nix # Import main user config (includes SSH keys and common modules)
  ];

  programs.worktrunk.enable = true;

  home.stateVersion = "25.11";
}
