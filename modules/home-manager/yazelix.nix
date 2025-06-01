# modules/home-manager/yazelix.nix
{ pkgs, ... }:

{
  home.activation = {
    installRustTools = {
      command = ''
        ${pkgs.cargo-binstall}/bin/cargo-binstall zellij yazi-cli yazi-fm zoxide --no-confirm || true
        ${pkgs.cargo-binstall}/bin/cargo-binstall cargo-update --no-confirm || true

        ${pkgs.rustc}/bin/cargo install-update -a || true # Update all installed cargo packages

      '';
      # This ensures the script only runs when relevant packages change
      # or when you explicitly rebuild your home-manager configuration.
      # This makes the activation script re-run when these packages are updated.
      depends = [
        "installPackages" # Run after Home Manager installs all packages
      ];
    };
  };
}
