#!/bin/bash

set -euo pipefail

hostname="oxenfurt"

packages=(
    intel-media-driver
    mesa
    vulkan-intel
    vulkan-icd-loader
    vulkan-tools
    sof-firmware
)

# the laptop needs no extra setup
device_setup() {
    :
}

# shellcheck disable=SC1091
# run the shared configure steps
source ./configure-common.sh
