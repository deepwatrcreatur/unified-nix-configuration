# Overlay for Grok CLI installation
# This overlay creates a wrapper for the @vibe-kit/grok-cli npm package
final: prev: {
  grok-cli = final.writeShellScriptBin "grok" ''
    exec ${final.nodejs}/bin/npx @vibe-kit/grok-cli "$@"
  '';
}