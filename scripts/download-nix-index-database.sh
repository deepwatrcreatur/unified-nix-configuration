#!/bin/bash

# Download the pre-generated nix-index database for the current system
download_nixpkgs_cache_index() {
  # Determine the filename based on architecture and OS
  filename="index-$(uname -m | sed 's/^arm64$/aarch64/')-$(uname | tr A-Z a-z)"
  mkdir -p ~/.cache/nix-index && cd ~/.cache/nix-index
  wget -q -N https://github.com/nix-community/nix-index-database/releases/latest/download/$filename
  ln -f $filename files
}

download_nixpkgs_cache_index
