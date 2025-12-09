{
  config,
  pkgs,
  inputs,
  ...
}:

{
  # Allow unfree packages for CUDA/NVIDIA tools
  nixpkgs.config.allowUnfree = true;
  imports = [
    ../../default.nix
    ./nh.nix
    ./just.nix
    ../../../../modules/home-manager/gpg-cli.nix
  ];

  home.homeDirectory = "/home/deepwatrcreatur";

  home.packages = with pkgs; [
    # GPU utilities that work well with Nix
    glxinfo # OpenGL info
    vulkan-tools # Vulkan utilities

    # Note: For GPU monitoring tools like nvtop, use system packages:
    # sudo apt install nvtop
    # This ensures compatibility with your system NVIDIA drivers
  ];

  # Set environment variables to help find system NVIDIA libraries
  home.sessionVariables = {
    LD_LIBRARY_PATH = "/usr/lib/x86_64-linux-gnu:\${LD_LIBRARY_PATH}";
  };

  home.stateVersion = "24.11";

  programs.attic-client.enable = true;
}
