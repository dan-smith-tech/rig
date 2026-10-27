#!/bin/bash

set -euo pipefail

hostname="novigrad"

packages=(
    nvidia-open
    nvidia-utils
    egl-wayland
    opencl-nvidia
    cuda
    nvidia-container-toolkit
    steam
    gamescope
    ollama-cuda
)

device_setup() {
    # enable the multilib repository
    sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
    sudo pacman -Syu --noconfirm
    # install the 32 bit nvidia driver
    sudo pacman -S --noconfirm lib32-nvidia-utils
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
    # wait for ollama and pull the model
    until ollama list > /dev/null 2>&1; do sleep 1; done
    ollama pull qwen3.6:27b
}

# run the shared configure steps
source ./configure-common.sh
