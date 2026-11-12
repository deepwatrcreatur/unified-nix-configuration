{
  config,
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    broot
    git

    ripgrep
    fd
    jq
    ast-grep
    just

    gh-dash

    gcc
    binutils
    gnumake
    pkg-config
  ];
}
