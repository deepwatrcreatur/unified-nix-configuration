# modules/home-manager/common/gcc-wrapper.nix - Generic GCC wrapper for mixed environments
{ pkgs, lib, config, ... }:

let
  gccWrapper = pkgs.writeShellScriptBin "gcc" ''
    # Prefer Homebrew GCC if available (for Homebrew packages)
    if command -v brew >/dev/null 2>&1; then
      # Use platform helper to find Homebrew GCC
      homebrew_gcc="${pkgs.platformHelpers.homebrewGcc}"
      
      if [ -f "$homebrew_gcc" ] && [ -x "$homebrew_gcc" ]; then
        exec "$homebrew_gcc" "$@"
      fi
    fi
    
    # Fallback to Nix GCC
    exec ${pkgs.gcc}/bin/gcc "$@"
  '';
in
{
  home.packages = [ gccWrapper ];
}
