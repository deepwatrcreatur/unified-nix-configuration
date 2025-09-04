#!/usr/bin/env bash
set -eu

# NixOS-compatible Homebrew installation script
# This script handles the PATH issues that occur when installing Homebrew on NixOS
# Run this script as root to ensure proper permissions and directory creation

brewPrefix="/home/linuxbrew/.linuxbrew"
commonBrews=("ccat" "doggo" "silicon")

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root (sudo $0)"
    exit 1
fi

# Create the linuxbrew directory with proper permissions
echo "Creating linuxbrew directory structure..."
mkdir -p "$brewPrefix"

# Find the first regular user (non-system user with UID >= 1000)
REGULAR_USER=$(getent passwd | awk -F: '$3 >= 1000 && $3 != 65534 { print $1; exit }')
if [ -n "$REGULAR_USER" ]; then
    USER_UID=$(id -u "$REGULAR_USER")
    USER_GID=$(id -g "$REGULAR_USER")
    echo "Setting ownership to $REGULAR_USER ($USER_UID:$USER_GID)"
    chown -R $USER_UID:$USER_GID "$brewPrefix"
    chmod 755 /home/linuxbrew
else
    echo "Warning: Could not find regular user, using root ownership"
fi

# Create symlinks for tools that homebrew installer expects in standard locations
echo "Creating symlinks for homebrew installer compatibility..."
mkdir -p /bin /usr/bin
ln -sf $(which bash) /bin/bash 2>/dev/null || true
ln -sf $(which mkdir) /bin/mkdir 2>/dev/null || true
ln -sf $(which chmod) /bin/chmod 2>/dev/null || true
ln -sf $(which chown) /bin/chown 2>/dev/null || true
ln -sf $(which chgrp) /bin/chgrp 2>/dev/null || true
ln -sf $(which touch) /bin/touch 2>/dev/null || true
ln -sf $(which cat) /bin/cat 2>/dev/null || true
ln -sf $(which readlink) /bin/readlink 2>/dev/null || true
ln -sf $(which rm) /bin/rm 2>/dev/null || true
ln -sf $(which stat) /usr/bin/stat 2>/dev/null || true
ln -sf $(which ldd) /usr/bin/ldd 2>/dev/null || true
ln -sf $(which curl) /bin/curl 2>/dev/null || true
ln -sf $(which git) /bin/git 2>/dev/null || true
ln -sf $(which tr) /bin/tr 2>/dev/null || true
ln -sf $(which mv) /bin/mv 2>/dev/null || true
ln -sf $(which shasum) /bin/shasum 2>/dev/null || true
ln -sf $(which sha256sum) /bin/sha256sum 2>/dev/null || true
ln -sf $(which cut) /bin/cut 2>/dev/null || true
ln -sf $(which flock) /bin/flock 2>/dev/null || true
ln -sf $(which tar) /bin/tar 2>/dev/null || true
ln -sf $(which gzip) /bin/gzip 2>/dev/null || true
ln -sf $(which wc) /bin/wc 2>/dev/null || true
ln -sf $(which grep) /bin/grep 2>/dev/null || true
ln -sf $(nix-shell -p ruby_3_4 --run "which ruby") /bin/ruby 2>/dev/null || true

# Function to run homebrew installation as regular user
install_homebrew() {
    if [ -n "$REGULAR_USER" ]; then
        echo "Switching to user $REGULAR_USER for homebrew installation..."
        sudo -u "$REGULAR_USER" bash -c '
            brewPrefix="/home/linuxbrew/.linuxbrew"
            commonBrews=("ccat" "doggo" "silicon")
            
            # Install Homebrew if not present
            if [ ! -f "${brewPrefix}/bin/brew" ]; then
                echo "Installing Homebrew to ${brewPrefix}..."
                
                # Set up comprehensive PATH for homebrew installer on NixOS
                export PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH"
                
                # Set environment variables for homebrew installer
                export HOMEBREW_CURL_PATH="/bin/curl"
                export HOMEBREW_GIT_PATH="/bin/git"
                export HOMEBREW_FORCE_VENDOR_RUBY=1
                
                # Run the installer with proper environment
                NONINTERACTIVE=1 bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi

            # Set up environment for package installation
            export PATH="${brewPrefix}/bin:${brewPrefix}/sbin:$PATH"
            export HOMEBREW_PREFIX="${brewPrefix}"
            export HOMEBREW_CELLAR="${brewPrefix}/Cellar"
            export HOMEBREW_REPOSITORY="${brewPrefix}/Homebrew"
            
            # Install common packages
            for formula in "${commonBrews[@]}"; do
                if ! "${brewPrefix}/bin/brew" list "$formula" &>/dev/null; then
                    echo "Installing formula: $formula"
                    "${brewPrefix}/bin/brew" install "$formula"
                fi
            done
            
            echo "All common brew packages installed!"
        '
    else
        echo "Error: No regular user found, cannot install homebrew"
        exit 1
    fi
}

# Run the homebrew installation
install_homebrew

echo ""
echo "Homebrew installation complete!"
echo ""
echo "To use homebrew packages, users should:"
echo "1. Add /home/linuxbrew/.linuxbrew/bin to their PATH"
echo "2. Run: eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\""
echo "3. Or configure their shell as shown in modules/home-manager/linuxbrew.nix"
echo ""
echo "Installed packages:"
for formula in "${commonBrews[@]}"; do
    echo "  - $formula"
done
echo ""
echo "Note: On NixOS, homebrew packages can be run with nix-ld enabled."