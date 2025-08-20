# Defining a Home Manager module for Zed editor
{ config, pkgs, lib, ... }:

{
  programs.zed-editor = {
    enable = true;

    # Specify the Zed package (optional override if needed)
    package = pkgs.zed-editor-fhs;

    # User settings for Zed, written to ~/.config/zed/settings.json
    userSettings = {
      # General editor settings
      theme = "Dracula"; 
      vim_mode = true; 
      relative_line_numbers = true; 
      buffer_font_size = 15; 
      buffer_font_family = "Fira Code";
      buffer_line_height = "comfortable"; # Line height for readability (1.618)

      # UI settings
      ui_font_size = 16;
      tab_bar.show = true; # Always show tab bar
      scrollbar.show = "never"; # Hide scrollbar for cleaner look
      indent_guides.enabled = true; 
      indent_guides.coloring = "indent_aware"; # Color based on indent level

      # Git integration
      git.git_panel.dock = "right"; # Place Git panel on the right
      git_status = true; # Show Git status in tabs

      # Language-specific settings
      languages = {
        TypeScript = {
          format_on_save = "on"; # Auto-format TypeScript files on save
          tab_size = 2;
        };
        Python = {
          format_on_save = "on"; # Auto-format Python files on save
          tab_size = 4; # Use 4 spaces for Python
        };
      };

      # Inlay hints for supported languages (e.g., Go, Rust, TypeScript)
      inlay_hints.enabled = true;

      # File finder settings
      file_finder.modal_width = "medium"; # Medium-sized file finder modal

      # Authentication settings for Zed collaboration and LLM features
      # Note: Zed uses GitHub OAuth; email is pulled from your GitHub profile
      accounts = {
        email = "deepwatrcreatur@gmail.com";
      };

      auto_install_extensions = [
        "nix"
        "python"
        "typescript"
        "markdown"
      ];
    };
  };

  # Ensure Vulkan support for Zed (required for GPU acceleration)
  # nixGL.vulkan.enable = true; Not applicable on macos

  # Symlink Zed CLI to ~/.local/bin/zed for easier terminal access
  home.file.".local/bin/zed".source = "${pkgs.zed-editor}/bin/zed";
}
