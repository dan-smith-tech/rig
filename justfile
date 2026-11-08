set shell := ["bash", "-euo", "pipefail", "-c"]

# --- common ---

packages := replace_regex("
    ark
    bluez
    bluez-utils
    brave-bin
    catppuccin-plasma-colorscheme-mocha
    dolphin
    gwenview
    kdeconnect
    kitty
    less
    okular
    openssh
    plasma
    python
    rtk-bin
    rustup
    sddm
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
    tmpdir="$(mktemp -d)"
    (
        cd "$tmpdir"
        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg -sir --noconfirm
    )
    rm -rf "$tmpdir"

    # install shared packages
    paru -S --needed --noconfirm --skipreview {{ packages }}
    # remove bloat
    sudo pacman -Rns discover plasma-workspace-wallpapers

    # initialise packages
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

    # sync the ollama system config override
    cd "{{ justfile_directory() }}/dotfiles"
    sudo stow --adopt -t / ollama
    git restore .

    # start ollama and pull the model
    sudo systemctl enable --now ollama
    until ollama list > /dev/null 2>&1; do sleep 1; done
    ollama pull qwen3.8:27b

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
    linux-headers
    nvidia-580xx-dkms
    nvidia-580xx-utils
    openssh
    qemu
    qemu-hw-usb-host
    virt-install
", '\s+', ' ')

_homelab:
    #!/usr/bin/env bash
    set -euo pipefail

    sudo -v

    # disable auto plasma boot
    sudo systemctl disable --now sddm

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

    # autologin only applies when sddm is started on demand
    sudo mkdir -p /etc/sddm.conf.d
    printf '[Autologin]\nUser=%s\nSession=plasma\n' "$USER" | sudo tee /etc/sddm.conf.d/autologin.conf > /dev/null

    # commands called over ssh by home assistant
    sudo tee /usr/local/bin/htpc-launch > /dev/null <<'EOF'
    #!/bin/sh
    app="${1:-${SSH_ORIGINAL_COMMAND:-}}"
    app="$(printf '%s' "$app" | tr '[:upper:]' '[:lower:]')"

    # close the app cleanly so the browser can flush its profile to disk
    stop_app() {
        pgrep -u "$USER" -f -- 'brave-htpc' > /dev/null || true
        pkill -TERM -u "$USER" -f -- 'brave-htpc' 2>/dev/null || true
        for _ in $(seq 1 15); do
            pgrep -u "$USER" -f -- 'brave-htpc' > /dev/null || break
            sleep 1
        done
        pkill -KILL -u "$USER" -f -- 'brave-htpc' 2>/dev/null || true
    }

    case "$app" in
        off|stop)
            stop_app
            sudo systemctl stop sddm
            sudo systemctl start getty@tty1
            sudo chvt 1
            ;;
        http://*|https://*)
            mkdir -p "$HOME/.cache"
            echo "$app" > "$HOME/.cache/htpc"
            stop_app
            sudo systemctl restart sddm
            ;;
        *)
            echo "usage: htpc-launch off | htpc-launch https://..." >&2
            exit 1
            ;;
    esac
    EOF
    sudo chmod 755 /usr/local/bin/htpc-launch

    sudo tee /usr/local/bin/htpc-session > /dev/null <<'EOF'
    #!/bin/sh
    # started by plasma, opens the requested url in brave
    url="$(cat "$HOME/.cache/htpc")"
    case "$url" in
        *youtube.com*)
            # the tv user agent and autoplay policy prevent a black screen after an off->youtube cycle
            exec brave \
                --password-store=basic \
                --user-data-dir="$HOME/.config/brave-htpc" \
                --user-agent='Mozilla/5.0 (PS4; Leanback Shell) Cobalt/26.lts.0-qa; compatible;' \
                --app='https://www.youtube.com/tv' \
                --autoplay-policy=no-user-gesture-required \
                --start-fullscreen
            ;;
    esac

    exec brave \
        --password-store=basic \
        --user-data-dir="$HOME/.config/brave-htpc" \
        --app="$url" \
        --start-fullscreen
    EOF
    sudo chmod 755 /usr/local/bin/htpc-session
    mkdir -p ~/.config/autostart
    printf '[Desktop Entry]\nType=Application\nName=HTPC session\nExec=/usr/local/bin/htpc-session\n' > ~/.config/autostart/htpc-session.desktop

homelab: _common _homelab
    sudo hostnamectl set-hostname nilfgaard
