#!/bin/bash

set -euo pipefail

# check if script is run from rig directory
if [ ! -f "$(pwd)/configure.sh" ]; then
    echo "Error: must be run from rig repository directory"
    exit 1
fi

# parse flags
IS_WORK=false
for arg in "$@"; do
    case "$arg" in
        --work) IS_WORK=true ;;
    esac
done

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
sudo pacman -S --noconfirm base-devel git neovim openssh python rustup stow zed zsh
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

# setup sddm autologin
sudo sed -i 's/^Session=$/Session=plasma.desktop/; s/^User=$/User='"$(whoami)"'/' /etc/sddm.conf.d/kde_settings.conf

# stop brave from prompting to unlock kwallet (unless on work setup, which uses kwallet)
mkdir -p "$HOME/.config"
if [ "$IS_WORK" = false ]; then
    echo '--password-store=basic' > "$HOME/.config/brave-flags.conf"
fi

# enable virtual keyboard
echo 'KWIN_IM_SHOW_ALWAYS=1' | sudo tee -a /etc/environment > /dev/null

# work setup
if [ "$IS_WORK" = true ]; then
    sudo pacman -S --noconfirm nodejs npm docker
    yay -S --noconfirm mattermost-desktop zoom
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$(whoami)"
fi

# manual configuration steps
echo ""
echo "Automatic configuration complete. Final manual steps:"
echo ""
echo "1. Open 'System Settings' and configure:"
echo "   - shortcuts"
echo "   - display"
echo "   - wallpaper"
echo "   - theme"
echo "   - panel settings"
echo ""
echo "2. Open brave://settings and configure:"
echo "   - privacy and security"
echo "   - no persistent cookies"
echo "   - no telemetry"
echo "   - Catppuccin Mocha theme"
echo ""
echo "3. Add the following public key to https://github.com/settings/keys:"
sed 's/^/   /' "$HOME/.ssh/id_ed25519.pub"
echo ""
echo "4. Sign into Steam and install games."
echo ""
