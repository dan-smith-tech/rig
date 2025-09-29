#!/bin/bash
# Arch Linux Post-Installation Setup Script
# Run this from the rig repository directory

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}
print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}
prompt_user() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        eval "$var_name=\"\${input:-$default}\""
    else
        read -p "$prompt: " input
        eval "$var_name=\"$input\""
    fi
}
# Function to prompt for yes/no
prompt_yn() {
    local prompt="$1"
    local default="$2"
    local response
    
    while true; do
        if [ "$default" = "y" ]; then
            read -p "$prompt [Y/n]: " response
            response=${response:-y}
        elif [ "$default" = "n" ]; then
            read -p "$prompt [y/N]: " response
            response=${response:-n}
        else
            read -p "$prompt [y/n]: " response
        fi
        
        case $response in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}
# Check if running from correct directory
if [ ! -f "$(pwd)/configure.sh" ]; then
    print_error "This script must be run from the rig repository directory"
    print_error "Make sure you're in the directory containing configure.sh"
    exit 1
fi

print_section "Arch Linux Automated Post-Installation Setup"
print_status "Running all post-installation steps automatically..."

# Get current username
CURRENT_USER=$(whoami)
print_status "Current user: $CURRENT_USER"

# Get user information
prompt_user "Enter hostname for the system" "HOSTNAME" "novigrad"

# Set hostname
sudo hostnamectl set-hostname "$HOSTNAME"

# ===========================================
# PACKAGE INSTALLATION
# ===========================================

# Ask about graphics drivers
GRAPHICS_DRIVER="nvidia"
if prompt_yn "Are you using NVIDIA graphics?" "y"; then
    GRAPHICS_DRIVER="nvidia"
else
    GRAPHICS_DRIVER="intel"
fi

# Ask about multilib/Steam installation
ENABLE_MULTILIB=false
if prompt_yn "Enable 32-bit multilib repository and install Steam?" "y"; then
    ENABLE_MULTILIB=true
fi

print_section "Package Installation"
print_status "Installing user-defined package dependencies..."

if [[ -f "packages.txt" ]]; then
    mapfile -t packages < <(grep -vE '^\s*#|^\s*$' packages.txt)
    if (( ${#packages[@]} )); then
        sudo pacman -S --noconfirm "${packages[@]}"
        print_status "All listed packages installed successfully."
    else
        print_status "No packages found to install in packages.txt."
    fi
else
    print_status "packages.txt not found. Skipping package installation."
fi

# Install additional packages based on graphics driver
if [ "$GRAPHICS_DRIVER" = "nvidia" ]; then
    echo "Installing NVIDIA packages..."
    sudo pacman -S --noconfirm nvidia-dkms nvidia-utils egl-wayland
else
    echo "Installing Intel/AMD graphics packages..."
    sudo pacman -S --noconfirm mesa intel-media-driver
fi

# Conditional multilib setup
if [ "$ENABLE_MULTILIB" = "true" ]; then
    echo "Setting up multilib repository and Steam..."

    # Enable multilib repository
    sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ { s/^#//; }' /etc/pacman.conf

    # Update package database
    sudo pacman -Syu --noconfirm

    # Install 32-bit packages based on graphics driver
    if [ "$GRAPHICS_DRIVER" = "nvidia" ]; then
        sudo pacman -S --noconfirm lib32-nvidia-utils steam
    else
        sudo pacman -S --noconfirm lib32-mesa steam
    fi

    echo "Multilib setup completed!"
else
    echo "Skipping multilib setup..."
fi

# ===========================================
# AUR HELPER INSTALLATION
# ===========================================

print_section "AUR Helper Installation"
if command -v yay &> /dev/null; then
    print_status "yay is already installed"
else
    print_status "Installing yay AUR helper..."

    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    # Clone and build yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm

    # Clean up
    cd "$HOME"
    rm -rf "$TEMP_DIR"

    print_status "yay installed successfully"
fi

# ===========================================
# AUR PACKAGE INSTALLATION
# ===========================================

print_section "Package Installation"
# Check if yay is available
if command -v yay &> /dev/null; then
    print_status "Installing Brave..."
    yay -S --noconfirm brave-bin
    print_status "Brave installed"
else
    print_warning "yay not available - skipping AUR package installation"
fi

# ===========================================
# SHELL CONFIGURATION
# ===========================================

print_section "Shell Configuration"
print_status "Setting ZSH as default shell..."
sudo chsh -s /usr/bin/zsh "$CURRENT_USER"
print_status "ZSH set as default shell (will take effect on next login)"

# ===========================================
# AUTO-LOGIN CONFIGURATION
# ===========================================

# print_section "Auto-login Configuration"
# print_status "Configuring auto-login for $CURRENT_USER..."
# # Create systemd override directory
# sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
# # Create override configuration
# sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null << EOF
# [Service]
# ExecStart=
# ExecStart=-/usr/bin/agetty --autologin $CURRENT_USER --noclear %I \$TERM
# EOF
# # Reload systemd and enable the service
# sudo systemctl daemon-reload
# sudo systemctl enable getty@tty1
# print_status "Auto-login configured for $CURRENT_USER"

# ===========================================
# SUDOERS CONFIGURATION
# ===========================================

print_section "Sudoers Configuration"
print_status "Configuring sudoers for $CURRENT_USER..."
# Remove any $CURRENT_USER lines from /etc/sudoers (with backup)
sudo cp /etc/sudoers /etc/sudoers.bak.$(date +%F-%H%M%S)
sudo sed -i "/^$CURRENT_USER\s/d" /etc/sudoers
# Add NOPASSWD rule for $CURRENT_USER to /etc/sudoers using visudo
SUDOERS_LINE="$CURRENT_USER ALL=(ALL) NOPASSWD: ALL"
if ! sudo grep -Fxq "$SUDOERS_LINE" /etc/sudoers; then
    print_status "Adding NOPASSWD rule for $CURRENT_USER to /etc/sudoers..."

    # Use a temp file to safely append via visudo
    TMP_SUDOERS=$(mktemp)
    sudo cp /etc/sudoers "$TMP_SUDOERS"

    # Fix permissions on temp file for visudo
    sudo chown root:root "$TMP_SUDOERS"
    sudo chmod 440 "$TMP_SUDOERS"

    # Add the new line
    echo "$SUDOERS_LINE" | sudo tee -a "$TMP_SUDOERS" > /dev/null

    # Validate syntax with visudo
    sudo visudo -c -f "$TMP_SUDOERS"
    if [ $? -eq 0 ]; then
        sudo cp "$TMP_SUDOERS" /etc/sudoers
        print_status "NOPASSWD rule added successfully."
    else
        print_error "ERROR: Syntax error in sudoers! Aborting change."
    fi
    sudo rm "$TMP_SUDOERS"
else
    print_status "NOPASSWD rule for $CURRENT_USER already present in /etc/sudoers."
fi
# Validate sudoers syntax
sudo visudo -c
print_status "Sudoers configuration complete for $CURRENT_USER"

# ===========================================
# USER GROUPS CONFIGURATION
# ==========================================

print_section "User Groups Configuration"
sudo usermod -aG uucp,tty $USER

# ===========================================
# DOCKER CONFIGURATION
# ===========================================

# Add user to docker group
if ! groups "$CURRENT_USER" | grep -q "\bdocker\b"; then
    print_status "Adding $CURRENT_USER to docker group..."
    sudo usermod -aG docker "$CURRENT_USER"
else
    print_status "$CURRENT_USER is already in the docker group."
fi

# Enable Docker service
if systemctl is-active --quiet docker; then
    print_status "Docker service is already running."
else
    print_status "Enabling and starting Docker service..."
    sudo systemctl enable docker
    sudo systemctl start docker
    print_status "Docker service started successfully."
fi

# ===========================================
# DOTFILES CONFIGURATION
# ===========================================

print_section "Dotfiles Configuration"
print_status "Setting up dotfiles with stow..."
# Check if dotfiles directory exists
if [ -d "$HOME/rig/dotfiles" ]; then
    # Run stow to symlink configuration files
    print_status "Running stow to symlink configuration files..."
    stow --adopt -t ~ -d "$HOME/rig/dotfiles" .

    # Restore original configs from repository
    print_status "Restoring original configurations from repository..."
    cd "$HOME/rig/dotfiles"
    git restore .
    cd ..

    print_status "Dotfiles configuration complete"
else
    print_error "dotfiles directory not found in $(pwd)"
    print_error "Make sure you're running this script from the rig repository root"
    exit 1
fi

# ===========================================
# GIT DIFFTOOL CONFIGURATION (KITTY)
# ===========================================

print_section "Git Diff Tool Configuration"
print_status "Configuring Kitty as the default git diff tool..."
git config --global diff.tool kitty
git config --global difftool.kitty.cmd 'kitten diff $LOCAL $REMOTE'
print_status "Kitty diff tool successfully configured for git"

# ===========================================
# TIME-DATE CONFIGURATION
# ===========================================

print_section "Time-Date Configuration"
sudo timedatectl set-timezone "Europe/London"
print_status "Enabling NTP..."
sudo timedatectl set-ntp true

# ===========================================
# FINALIZATION
# ===========================================

print_status "Configuration complete."
for i in {3..1}; do
    echo -ne "\rRebooting in $i seconds..."
    sleep 1
done
echo -e "\nRebooting now..."
sudo reboot
