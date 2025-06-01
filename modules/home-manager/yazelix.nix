# modules/home-manager/yazelix.nix
{ pkgs, ... }:

{
  home.activation = {
    installRustTools.text = ''
      # Ensure ~/.cargo/bin exists
      mkdir -p "$HOME/.cargo/bin"

      ${pkgs.cargo-binstall}/bin/cargo-binstall \
        zellij \
        yazi-cli \
        yazi-fm \
        zoxide \
        --force --no-confirm || true

      ${pkgs.cargo-binstall}/bin/cargo-binstall \
        cargo-update \
        --force --no-confirm || true

      # Now that cargo-update is installed by cargo-binstall (and thus in ~/.cargo/bin)
      # we can use cargo install-update.
      if command -v cargo-update &> /dev/null; then
        ${pkgs.rustc}/bin/cargo install-update -a || true
      else
        echo "Warning: cargo-update not found. Skipping cargo install-update commands."
        echo "Please check if cargo-binstall installed cargo-update successfully."
      fi
    '';
    installRustTools.depends = [
      "installPackages" # Run after Home Manager installs all packages
    ];
  };
}
