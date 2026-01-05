{
  imports = [
    ../../default.nix # Import main user config (includes SSH keys and common modules)
  ];

  home.stateVersion = "25.11";
}
