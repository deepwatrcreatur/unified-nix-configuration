# Configure git to use SSH for GitHub system-wide
# This allows nix flake operations to use SSH keys instead of HTTPS
# which avoids GitHub API rate limits
{ pkgs, ... }:

{
  # System-wide git config (applies to root and all users without their own config)
  environment.etc."gitconfig".text = ''
    [url "ssh://git@github.com/"]
      insteadOf = https://github.com/
  '';
}
