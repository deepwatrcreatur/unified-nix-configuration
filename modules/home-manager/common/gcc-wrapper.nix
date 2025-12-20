# modules/home-manager/common/gcc-wrapper.nix - Generic GCC wrapper for mixed environments
{ pkgs, lib, ... }:

let
  gccWrapper = pkgs.writeShellScriptBin "gcc" ''
    # Prefer Homebrew GCC if available (for Homebrew packages)
    if command -v brew >/dev/null 2>&1; then
      # Try different Homebrew GCC locations
      for gcc_cmd in \
        "$(brew --prefix gcc)/bin/gcc" \
        "/usr/local/bin/gcc-"* \
        "/opt/homebrew/bin/gcc-"* \
        "$(brew --prefix)/bin/gcc-"*; do
        if [ -f "$gcc_cmd" ] && [ -x "$gcc_cmd" ]; then
          # Find the first actual gcc executable
          for cmd in $gcc_cmd; do
            if [ -f "$cmd" ] && [ -x "$cmd" ]; then
              exec "$cmd" "$@"
            fi
          done
        fi
      done
      
      # Fallback to find any gcc in Homebrew bin
      HOMEBREW_BIN="''${HOMEBREW_PREFIX:-$(brew --prefix 2>/dev/null)}/bin"
      if [ -d "$HOMEBREW_BIN" ]; then
        for gcc in "$HOMEBREW_BIN"/gcc-*; do
          if [ -f "$gcc" ] && [ -x "$gcc" ]; then
            exec "$gcc" "$@"
          fi
        done
      fi
    fi
    
    # Fallback to Nix GCC
    exec ${pkgs.gcc}/bin/gcc "$@"
  '';
in
{
  home.packages = [ gccWrapper ];
}
