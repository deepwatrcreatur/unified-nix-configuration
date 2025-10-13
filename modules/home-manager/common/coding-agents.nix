{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    claude-code
    claude-monitor
    cursor-cli
    gemini-cli
    # opencode  # Temporarily disabled due to hash mismatch in node_modules
  ];
}
