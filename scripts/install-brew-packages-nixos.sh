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

# Create symlinks for essential tools (suppress errors for cleaner output)
SYSTEM_BIN="/run/current-system/sw/bin"

# Core system tools
tools_bin=(
    bash mkdir chmod chown chgrp touch cat readlink rm
    curl git tr mv cut tar gzip wc grep ls find sed awk
    sort uniq xargs ps id whoami uname which flock
)

for tool in "${tools_bin[@]}"; do
    ln -sf "$SYSTEM_BIN/$tool" "/bin/$tool" 2>/dev/null || true
done

# Tools that go in /usr/bin
tools_usr_bin=(stat ldd shasum sha256sum)
for tool in "${tools_usr_bin[@]}"; do
    ln -sf "$SYSTEM_BIN/$tool" "/usr/bin/$tool" 2>/dev/null || true
done

# Ruby needs special handling since it's not in base system
echo "Setting up Ruby..."
ln -sf $(nix-shell -p ruby_3_4 --run "which ruby" 2>/dev/null) /bin/ruby 2>/dev/null || true

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