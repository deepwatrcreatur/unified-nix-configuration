# modules/home-manager/gemini-cli.nix
{ config, pkgs, lib, ... }:

{
  options.myModules.claudeCode = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install Claude Code.";
    };
  };

  config = lib.mkIf config.myModules.claudeCode.enable {
    # Install via npm using home activation (relies on npm.nix for PATH setup)
    home.activation.installClaudeCode = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [[ -z "$DRY_RUN_CMD" ]]; then
        if ! command -v claude &> /dev/null; then
          echo "Installing @anthropic-ai/claude-code..."
          # Set PATH explicitly to include nodejs for npm's postinstall scripts
          PATH="${pkgs.nodejs}/bin:$PATH" ${pkgs.nodejs}/bin/npm install -g @anthropic-ai/claude-code
        fi
      fi
    '';
  };
}
