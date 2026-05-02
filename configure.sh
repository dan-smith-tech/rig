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

sudo pacman -S --noconfirm base-devel github-cli rustup stow zed zsh
yay -S --noconfirm brave-bin catppuccin-plasma-colorscheme-mocha

sudo chsh -s /usr/bin/zsh "$CURRENT_USER"

ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N ""

read -p "Git email: " git_email
git config --global user.email "$git_email"

read -p "Git name: " git_name
git config --global user.name "$git_name"

gh auth login

rustup default stable

sudo usermod -aG docker "$CURRENT_USER"

cd "$HOME/rig/dotfiles"
stow --adopt -t ~ nvim kitty zshrc zed gitignore
git restore .
cd ..

git config --global pull.rebase true
git config --global core.excludesfile '~/.gitignore_global'
git config --global core.editor nvim
git config --global diff.tool kitty
git config --global difftool.kitty.cmd 'kitten diff $LOCAL $REMOTE'

sudo timedatectl set-timezone "Europe/London"
sudo timedatectl set-ntp true

sudo pacman -S --noconfirm cups cups-pdf system-config-printer print-manager
sudo systemctl enable --now cups.service
sudo usermod -aG lp "$CURRENT_USER"

yay -S --noconfirm xone-dkms-git xone-dongle-firmware linux-headers
sudo mkinitcpio -P

sudo reboot
