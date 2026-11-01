set shell := ["bash", "-euo", "pipefail", "-c"]

# --- common ---

packages := replace_regex("
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
    kscreen
    kwallet-pam
    kitty
    less
    okular
    openssh
    plasma-desktop
    plasma-nm
    plasma-pa
    python
    rustup
    sddm
    sddm-kcm
    spectacle
    stow
    tesseract
    tesseract-data-eng
    wireguard-tools
    uv
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
    paru -S --needed --noconfirm --skipreview {{ packages }}
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

# --- pc ---

pc_packages := replace_regex("
    gamescope
    lib32-nvidia-utils
    nvidia-open
    nvidia-utils
    ollama-cuda
    steam
", '\s+', ' ')

_pc:
    #!/usr/bin/env bash
    set -euo pipefail

    # enable lib-32 support by enabling multilib
    sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
    sudo pacman -Syu --noconfirm

    paru -S --needed --noconfirm --skipreview {{ pc_packages }}

    # configure and start ollama
    sudo systemctl enable --now ollama
    until ollama list > /dev/null 2>&1; do sleep 1; done
    ollama pull qwen3.8:27b

    # expose ollama on the lan
    sudo mkdir -p /etc/systemd/system/ollama.service.d
    printf '[Service]\nEnvironment="OLLAMA_HOST=0.0.0.0"\n' | sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null
    sudo systemctl daemon-reload

pc: _common _pc
    sudo hostnamectl set-hostname novigrad

# --- laptop ---

laptop_packages := replace_regex("
    intel-media-driver
    mesa
    sof-firmware
    vulkan-icd-loader
    vulkan-intel
", '\s+', ' ')

_laptop:
    paru -S --needed --noconfirm --skipreview {{ laptop_packages }}

laptop: _common _laptop
    sudo hostnamectl set-hostname skellige

# --- work ---

work_packages := replace_regex("
    docker
    docker-compose
    libreoffice-still
    nodejs
    npm
    php
", '\s+', ' ')

_work:
    paru -S --needed --noconfirm --skipreview {{ work_packages }}
    sudo usermod -aG docker "$USER"
    sudo systemctl enable --now docker

work: _common _laptop _work
    sudo hostnamectl set-hostname oxenfurt

# --- homelab ---

homelab_packages := replace_regex("
    libvirt
    nftables
    nvidia-open
    nvidia-utils
    openssh
    qemu
    qemu-hw-usb-host
    virt-install
", '\s+', ' ')

_homelab:
    #!/usr/bin/env bash
    set -euo pipefail

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

    # replace the wired interface with a bridge for port forwarding
    wired="$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2=="ethernet"{print $1; exit}')"
    if [ -z "$wired" ]; then
        echo "No wired interface found"
        exit 1
    fi
    sudo nmcli con add type bridge ifname br0 con-name br0 ipv4.method auto ipv6.method ignore
    sudo nmcli con add type bridge-slave ifname "$wired" con-name "${wired}-slave" master br0
    sudo nmcli con up br0

    # install the packages
    paru -S --needed --noconfirm --skipreview {{ homelab_packages }}

    # allow remote access
    sudo systemctl enable sshd

    # download the latest home assistant image
    workdir="/var/lib/libvirt/images/haos"
    compressed="${workdir}/haos.qcow2.xz"
    image="${workdir}/haos.qcow2"
    ha_url="$(curl -fsSL https://api.github.com/repos/home-assistant/operating-system/releases/latest \
        | grep '"browser_download_url"' \
        | grep 'haos_ova-' \
        | grep '\.qcow2\.xz' \
        | cut -d '"' -f4 \
        | head -n1)"
    sudo mkdir -p "$workdir"
    sudo curl -fL "$ha_url" -o "$compressed"
    sudo xz -dkf "$compressed"
    sudo rm -f "$compressed"

    # create and autostart the home assistant vm
    sudo systemctl enable --now libvirtd
    sudo virt-install \
        --name haos \
        --description "Home Assistant OS" \
        --os-variant=generic \
        --virt-type kvm \
        --ram=8192 \
        --vcpus=4 \
        --disk "${image},bus=scsi" \
        --controller type=scsi,model=virtio-scsi \
        --network bridge=br0,model=virtio \
        --hostdev 003.003 \
        --import \
        --graphics none \
        --boot uefi
    sudo virsh autostart haos

homelab: _homelab
    sudo hostnamectl set-hostname nilfgaard
