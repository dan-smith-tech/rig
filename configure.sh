#!/bin/bash

set -e

# check if script is run from rig directory
if [ ! -f "$(pwd)/configure.sh" ]; then
    echo "Error: must be run from rig repository directory"
    exit 1
fi

# set hostname
read -r -p "Hostname [novigrad]: " HOSTNAME
sudo hostnamectl set-hostname "${HOSTNAME:-novigrad}"

# install yay if not already installed
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

# install packages
sudo pacman -S --noconfirm base-devel github-cli rustup stow zed zsh
yay -S --noconfirm brave-bin catppuccin-plasma-colorscheme-mocha

# sync configs
cd "$HOME/rig/dotfiles"
stow --adopt -t ~ nvim kitty zshrc zed gitignore
git restore .
cd ..

# set zsh as default shell
sudo chsh -s /usr/bin/zsh "$(whoami)"

# setup git
git config --global pull.rebase true
git config --global core.excludesfile '~/.gitignore_global'
git config --global core.editor nvim
git config --global diff.tool kitty
git config --global difftool.kitty.cmd 'kitten diff $LOCAL $REMOTE'
read -p "Git email: " git_email
git config --global user.email "$git_email"
read -p "Git name: " git_name
git config --global user.name "$git_name"
gh auth login

# setup rust
rustup default stable

# enable virtual keyboard
echo 'KWIN_IM_SHOW_ALWAYS=1' | sudo tee -a /etc/environment

sudo reboot
