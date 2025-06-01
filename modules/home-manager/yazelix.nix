# modules/home-manager/yazelix.nix
{ pkgs, ... }:

{
  home.activation = {
    installRustTools = {
      text = ''
        # Ensure ~/.cargo/bin exists
        mkdir -p "$HOME/.cargo/bin"

        "${pkgs.cargo-binstall}/bin/cargo-binstall" \
          zellij \
          yazi-cli \
          yazi-fm \
          zoxide \
          --force --no-confirm || true

        "${pkgs.cargo-binstall}/bin/cargo-binstall" \
          cargo-update \
          --force --no-confirm || true

        if command -v cargo-update >/dev/null 2>&1; then
          "${pkgs.rustc}/bin/cargo" install-update -a || true
        else
          echo "Warning: cargo-update not found. Skipping cargo install-update commands."
          echo "Please check if cargo-binstall installed cargo-update successfully."
        fi
      '';
      depends = [
        "installPackages" # This ensures the script runs after packages are symlinked
      ];
    };
  };
}
