#!/bin/bash

set -euo pipefail

# set hostname
read -r -p "Hostname [novigrad]: " HOSTNAME
sudo hostnamectl set-hostname "${HOSTNAME:-novigrad}"

# install paru
tmpdir="$(mktemp -d)"
cd "$tmpdir"
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si --noconfirm
cd "$HOME"
rm -rf "$tmpdir"

# install packages
paru -S --needed --noconfirm --skipreview less neovim openssh ollama-cuda python rustup stow zed zsh brave-bin catppuccin-plasma-colorscheme-mocha

# sync configs
cd "$HOME/rig/dotfiles"
stow --adopt -t ~ nvim kitty zshrc zed gitignore
git restore .
cd ..

# set zsh as default shell
sudo chsh -s /usr/bin/zsh "$(whoami)"

# setup git
git config --global pull.rebase true
git config --global core.excludesfile "$HOME/.gitignore_global"
git config --global core.editor nvim
git config --global diff.tool kitty
git config --global difftool.kitty.cmd 'kitten diff $LOCAL $REMOTE'
read -r -p "Git email: " git_email
git config --global user.email "$git_email"
read -r -p "Git name: " git_name
git config --global user.name "$git_name"

# setup ssh key
ssh-keygen -t ed25519 -C "$git_email" -f "$HOME/.ssh/id_ed25519"

# setup ollama
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null << 'EOF'
[Service]
Environment="OLLAMA_CONTEXT_LENGTH=32768"
Environment="OLLAMA_FLASH_ATTENTION=1"
Environment="OLLAMA_KV_CACHE_TYPE=q8_0"
Environment="OLLAMA_KEEP_ALIVE=-1"
EOF
sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl restart ollama
ollama pull qwen3.6:27b

echo "Automated setup complete. Continue with manual configuration detailed in \`configure.md\`."
