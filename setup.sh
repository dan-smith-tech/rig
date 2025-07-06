#!/bin/bash

# Automated Post-Installation Setup Script for Arch Linux
# This script runs all post-installation steps without prompts
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
if [ ! -f "$(pwd)/setup.sh" ]; then
    print_error "This script must be run from the rig repository directory"
    print_error "Make sure you're in the directory containing setup.sh"
    exit 1
fi

print_section "Arch Linux Automated Post-Installation Setup"
print_status "Running all post-installation steps automatically..."

# Get current username
CURRENT_USER=$(whoami)
print_status "Current user: $CURRENT_USER"

# ===========================================
# SHELL CONFIGURATION
# ===========================================

print_section "Shell Configuration"
print_status "Setting ZSH as default shell..."
chsh -s /usr/bin/zsh
print_status "ZSH set as default shell (will take effect on next login)"

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
# PACKAGE INSTALLATION
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
# AUTO-LOGIN CONFIGURATION
# ===========================================

print_section "Auto-login Configuration"
print_status "Configuring auto-login for $CURRENT_USER..."

# Create systemd override directory
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d

# Create override configuration
sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null << EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $CURRENT_USER --noclear %I \$TERM
EOF

# Reload systemd and enable the service
sudo systemctl daemon-reload
sudo systemctl enable getty@tty1

print_status "Auto-login configured for $CURRENT_USER"

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
# DWM INSTALLATION
# ===========================================

print_section "DWM Window Manager Installation"
print_status "Installing and configuring DWM..."

# Clone DWM repository
if [ -d "/usr/local/src/dwm" ]; then
    print_status "DWM already exists, removing old version..."
    sudo rm -rf /usr/local/src/dwm
fi

print_status "Cloning DWM repository..."
sudo mkdir -p /usr/local/src
cd /usr/local/src
sudo git clone https://git.suckless.org/dwm
cd dwm

# Copy custom configuration
if [ -f "$HOME/rig/build/config.def.h" ]; then
    print_status "Copying custom DWM configuration..."
    sudo cp "$HOME/rig/build/config.def.h" config.def.h
    
    # Remove existing config.h if it exists
    if [ -f "config.h" ]; then
        print_status "Removing existing config.h..."
        sudo rm -f config.h
    fi
    
    print_status "Building and installing DWM..."
    sudo make clean install
    
    print_status "DWM installed successfully"
else
    print_error "DWM configuration file not found at $HOME/rig/build/config.def.h"
    print_error "Installing DWM with default configuration..."
    sudo make clean install
fi

# Prompt for laptop/desktop status bar config
if prompt_yn "Use laptop status bar" "n"; then
    sudo cp ~/rig/build/status-laptop.sh /usr/local/src/dwm/status.sh
else
    sudo cp ~/rig/build/status-pc.sh /usr/local/src/dwm/status.sh
fi
sudo chmod +x /usr/local/src/dwm/status.sh

# Return to original directory
cd "$HOME/rig"

# ===========================================
# COMPLETION
# ===========================================

print_section "Automated Post-Installation Setup Complete"
print_warning "System will reboot in 3 seconds..."

for i in {3..1}; do
    echo -ne "\rRebooting in $i seconds... "
    sleep 1
done

echo -e "\nRebooting now..."
reboot
