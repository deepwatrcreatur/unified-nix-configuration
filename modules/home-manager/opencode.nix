# modules/home-manager/opencode.nix
{ config, pkgs, lib, ... }:

{
  options.myModules.opencode = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install opencode-ai.";
    };
  };

  config = lib.mkIf config.myModules.opencode.enable {
    # Install via npm using home activation (relies on npm.nix for PATH setup)
    home.activation.installOpencode = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [[ -z "$DRY_RUN_CMD" ]]; then
        if ! command -v opencode &> /dev/null; then
          echo "Installing opencode-ai..."
          # Set PATH explicitly to include nodejs for npm's postinstall scripts
          PATH="${pkgs.nodejs}/bin:$PATH" ${pkgs.nodejs}/bin/npm install -g opencode-ai@latest
        fi
      fi
    '';
  };
}
