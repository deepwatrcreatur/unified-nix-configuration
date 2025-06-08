# Imported ONLY by macOS hosts.
{ ... }:

{
  imports = [
    ./standalone-hm.nix   # Get Nix Profile PATH
  ];

  # This adds the Homebrew path.
  home.sessionPath = [ "/opt/homebrew/bin" ];
}
