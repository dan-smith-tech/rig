#!/bin/bash

set -e

if [ ! -f "$(pwd)/configure.sh" ]; then
    echo "Error: must be run from rig repository directory"
    exit 1
fi

CURRENT_USER=$(whoami)

read -p "Hostname (default novigrad): " hostname
HOSTNAME=${hostname:-novigrad}
sudo hostnamectl set-hostname "$HOSTNAME"

if command -v yay &> /dev/null; then
    :
else
    cd $(mktemp -d)
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd "$HOME"
    rm -rf $(pwd)/../yay*
fi

sudo pacman -S --noconfirm base-devel git docker docker-buildx docker-compose fd fzf github-cli kitty less nodejs npm openssh ripgrep rustup stow sysstat tree-sitter-cli ttf-dejavu ttf-jetbrains-mono-nerd ttf-liberation ttf-nerd-fonts-symbols-mono unzip wget wl-clipboard zoxide zsh

yay -S --noconfirm brave-bin
yay -S --noconfirm catppuccin-plasma-colorscheme-mocha
yay -S --noconfirm zoom
sudo pacman -S --noconfirm mattermost-desktop
curl -f https://zed.dev/install.sh | sh

sudo chsh -s /usr/bin/zsh "$CURRENT_USER"

ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N ""

read -p "Git email: " git_email
git config --global user.email "$git_email"

read -p "Git name: " git_name
git config --global user.name "$git_name"

gh auth login

sudo usermod -aG docker "$CURRENT_USER"

cd "$HOME/rig/dotfiles"
stow --adopt -t ~ nvim kitty zshrc zed
git restore .
cd ..

git config --global pull.rebase true
git config --global diff.tool kitty
git config --global difftool.kitty.cmd 'kitten diff $LOCAL $REMOTE'

sudo timedatectl set-timezone "Europe/London"
sudo timedatectl set-ntp true

yay -S xone-dkms-git xone-dongle-firmware linux-headers
sudo mkinitcpio -P

sudo reboot
