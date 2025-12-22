# modules/home-manager/starship.nix - Clean Starship prompt with gruvbox theme
{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {
      # Clean prompt showing only character
      format = """
        $character
      """;
      
      # Gruvbox dark theme with Linux icon 󰌽
      palette = "gruvbox_dark";
      
      # OS-specific icons (only show the current OS)
      os.disabled = false;
      os.format = "$symbol";
      
      # Don't show git info in prompt for cleaner look
      git.disabled = false;
      
      # Directory styling (cyan color)
      directory.style = "color_aqua";
      directory.truncate_to_repo = false;
    };
  };
}
}