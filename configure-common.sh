#!/bin/bash

# this file is sourced by a device script and never run directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "source configure-common.sh from configure-pc.sh or configure-laptop.sh"
    exit 1
fi

shared_packages=(
    base-devel
    git
    less
    openssh
    python
    rustup
    stow
    zed
    zsh
    brave-bin
    catppuccin-plasma-colorscheme-mocha
    plasma-desktop
    sddm
    kitty
    dolphin
    ark
    gwenview
    okular
    tesseract
    tesseract-data-eng
    bluez
    bluez-utils
    bluedevil
)

# collect the git identity before long running steps
read -r -p "Git name: " git_name
read -r -p "Git email: " git_email
sudo -v

# set the device hostname
sudo hostnamectl set-hostname "$hostname"

# install the build tools needed by paru
sudo pacman -S --needed --noconfirm base-devel git

# install paru
tmpdir="$(mktemp -d)"
(
    cd "$tmpdir"
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -sir
)
rm -rf "$tmpdir"

# install the shared and device packages
paru -S --needed --noconfirm --skipreview "${shared_packages[@]}" "${packages[@]}"
rustup default stable

# run the device specific setup
device_setup

# enable the display manager and bluetooth
sudo systemctl enable sddm bluetooth

# sync the dotfiles
repo="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
(
    cd "$repo/dotfiles" || exit
    stow --adopt -t ~ nvim kitty zshrc zed gitignore
    git restore .
)

# set zsh as the default shell
sudo chsh -s /usr/bin/zsh "$(whoami)"

# set the git defaults
git config --global pull.rebase true
git config --global core.excludesfile "$HOME/.gitignore_global"
git config --global core.editor nvim
git config --global diff.tool kitty
git config --global difftool.kitty.cmd 'kitten diff $LOCAL $REMOTE'
git config --global user.email "$git_email"
git config --global user.name "$git_name"

# generate ssh key
ssh-keygen -t ed25519 -C "$git_email" -f "$HOME/.ssh/id_ed25519"

# point to the manual steps
echo "setup complete, continue with the manual steps in configure.md"
