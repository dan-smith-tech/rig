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

yay -S --noconfirm brave-bin
curl -f https://zed.dev/install.sh | sh

sudo chsh -s /usr/bin/zsh "$CURRENT_USER"

ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N ""

sudo usermod -aG docker "$CURRENT_USER"

stow --adopt -t ~ nvim kitty zshrc
cd "$HOME/rig/dotfiles"
git restore .
cd ..

git config --global diff.tool kitty
git config --global difftool.kitty.cmd 'kitten diff $LOCAL $REMOTE'

sudo timedatectl set-timezone "Europe/London"
sudo timedatectl set-ntp true

sudo reboot
