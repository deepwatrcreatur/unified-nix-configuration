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
    mesa-demos # OpenGL info
    vulkan-tools # Vulkan utilities

    # Note: For GPU monitoring tools like nvtop, use system packages:
    # sudo apt install nvtop
    # This ensures compatibility with your system NVIDIA drivers
  ];

  # Note: Do NOT set LD_LIBRARY_PATH globally - it breaks Nix binaries by
  # making them load system libraries (e.g., wrong OpenSSL version).
  # For NVIDIA/CUDA, use nixGL wrappers or run GPU apps with:
  #   LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH ./gpu-app

  home.stateVersion = "24.11";

  programs.attic-client.enable = true;
}
