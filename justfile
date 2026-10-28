set shell := ["bash", "-euo", "pipefail", "-c"]

shared := replace_regex("
    ark
    base-devel
    bluedevil
    bluez
    bluez-utils
    brave-bin
    catppuccin-plasma-colorscheme-mocha
    dolphin
    git
    gwenview
    kitty
    less
    okular
    openssh
    plasma-desktop
    python
    rustup
    sddm
    stow
    tesseract
    tesseract-data-eng
    zed
    zsh
", '\s+', ' ')

_common:
    #!/usr/bin/env bash
    set -euo pipefail

    # collect the git identity before long running steps
    read -r -p "Git name: " git_name
    read -r -p "Git email: " git_email
    sudo -v

    # install paru
    sudo pacman -Syu --needed --noconfirm base-devel git
    tmpdir="$(mktemp -d)"
    (
        cd "$tmpdir"
        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg -sir --noconfirm
    )
    rm -rf "$tmpdir"

    # install the shared packages
    paru -S --needed --noconfirm --skipreview {{ shared }}
    rustup default stable
    sudo systemctl enable sddm bluetooth

    # sync the dotfiles
    cd "{{ justfile_directory() }}/dotfiles"
    stow --adopt -t ~ nvim kitty zshrc zed gitignore
    git restore .

    # set zsh as the default shell
    sudo chsh -s /usr/bin/zsh "$USER"

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

_pc:
    #!/usr/bin/env bash
    set -euo pipefail

    # enable multilib before installing anything from it
    sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
    sudo pacman -Syu --noconfirm
    paru -S --needed --noconfirm --skipreview cuda egl-wayland gamescope lib32-nvidia-utils nvidia-container-toolkit nvidia-open nvidia-utils ollama-cuda opencl-nvidia steam

    # configure and start ollama
    sudo mkdir -p /etc/systemd/system/ollama.service.d
    sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null << 'EOF'
    [Service]
    Environment="OLLAMA_CONTEXT_LENGTH=32768"
    Environment="OLLAMA_FLASH_ATTENTION=1"
    Environment="OLLAMA_KV_CACHE_TYPE=q8_0"
    Environment="OLLAMA_KEEP_ALIVE=-1"
    EOF
    sudo systemctl daemon-reload
    sudo systemctl enable --now ollama
    until ollama list > /dev/null 2>&1; do sleep 1; done
    ollama pull qwen3.6:27b

pc: _common _pc
    sudo hostnamectl set-hostname novigrad

_laptop:
    paru -S --needed --noconfirm --skipreview intel-media-driver mesa sof-firmware vulkan-icd-loader vulkan-intel vulkan-tools

laptop: _common _laptop
    sudo hostnamectl set-hostname skellige

_work:
    paru -S --needed --noconfirm --skipreview docker docker-compose libreoffice-still nodejs npm php
    sudo usermod -aG docker "$USER"

work: _common _laptop _work
    sudo hostnamectl set-hostname oxenfurt
