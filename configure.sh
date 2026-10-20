#!/bin/bash

set -euo pipefail

# check if script is run from rig directory
if [ ! -f "$(pwd)/configure.sh" ]; then
    echo "Error: must be run from rig repository directory"
    exit 1
fi

# set hostname
read -r -p "Hostname [novigrad]: " HOSTNAME
sudo hostnamectl set-hostname "${HOSTNAME:-novigrad}"

# install yay
tmpdir="$(mktemp -d)"
cd "$tmpdir"
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd "$HOME"
rm -rf "$tmpdir"

# install packages
sudo pacman -S --noconfirm base-devel less neovim openssh ollama-cuda python rustup stow zed zsh
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
git config --global core.excludesfile "$HOME/.gitignore_global"
git config --global core.editor nvim
git config --global diff.tool kitty
git config --global difftool.kitty.cmd 'kitten diff $LOCAL $REMOTE'
read -r -p "Git email: " git_email
git config --global user.email "$git_email"
read -r -p "Git name: " git_name
git config --global user.name "$git_name"

# setup ssh key for github
ssh-keygen -t ed25519 -C "$git_email" -f "$HOME/.ssh/id_ed25519"

# setup rust
rustup default stable

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

# setup sddm autologin
sudo mkdir -p /etc/sddm.conf.d
sudo tee /etc/sddm.conf.d/kde_settings.conf > /dev/null << EOF
[Autologin]
Session=plasma.desktop
User=$(whoami)
EOF

# stop brave from prompting to unlock kwallet
mkdir -p "$HOME/.config"
echo '--password-store=basic' > "$HOME/.config/brave-flags.conf"

# enable virtual keyboard
echo 'KWIN_IM_SHOW_ALWAYS=1' | sudo tee -a /etc/environment > /dev/null

# extra work-specific tools
sudo pacman -S --noconfirm php nodejs npm docker docker-compose
sudo usermod -aG docker "$(whoami)"
# enable php iconv for phpactor language server in Zed
if grep -Eq '^[;[:space:]]*extension[[:space:]]*=[[:space:]]*iconv([.]so)?[[:space:]]*$' /etc/php/php.ini; then
    sudo sed -Ei 's|^[;[:space:]]*extension[[:space:]]*=[[:space:]]*iconv([.]so)?[[:space:]]*$|extension=iconv|' /etc/php/php.ini
elif ! grep -Eq '^[[:space:]]*extension[[:space:]]*=[[:space:]]*iconv([[:space:]]*)$' /etc/php/php.ini; then
    echo 'extension=iconv' | sudo tee -a /etc/php/php.ini > /dev/null
fi

echo "Automated setup complete. Continue with manual configuration detailed in \`configure.md\`."
