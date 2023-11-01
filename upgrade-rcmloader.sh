#!/usr/bin/env bash

set -e

if [ -z "$1" ]; then
    echo "Usage: ./upgrade-rcmloader.sh /path-to-loader/root"
    exit 1
fi

loader_mount_usb_path="$1"

cleanup() {
    rm -rf .tmp
    mkdir -p .tmp

    rm -rf .tmp/atmopshere
    mkdir -p .tmp/hekate
}

download_hekate() {
    echo Downloading latest hekate
    hekate_zip_url=$(curl -Ls https://api.github.com/repos/CTCaer/hekate/releases/latest | grep  hekate_ctcaer | grep browser_download_url  | cut -d '"' -f 4)
    curl -o .tmp/hekate.zip -L $hekate_zip_url
    unzip -o .tmp/hekate.zip -d .tools/hekate
    hekate_payload_bin_path=$(find .tools/hekate -type f -name 'hekate_*.bin')
}

wait_loader_mount() {
    echo "Waiting for RCM Loader mount... please mount USB Mass Storage"
    while [ ! -d "$loader_mount_usb_path" ]; do sleep 1; done
    echo RCM Loader mounted
}

copy_hekate() {
    echo Copying hekate
    mkdir -p "$loader_mount_usb_path/ATMOSPHERE_HEKATE"
    cp -arf $hekate_payload_bin_path "$loader_mount_usb_path/ATMOSPHERE_HEKATE/payload.bin"
}

create_safe_configs() {
    # don't patch sysmmc
    if [ ! -f ".tools/atmosphere/config/sys-patch/config.ini" ]; then
        mkdir -p .tools/atmosphere/config/sys-patch
        cp ./sys-patch-config.ini .tools/atmosphere/config/sys-patch/config.ini
    fi
}

cleanup
download_hekate
wait_loader_mount
copy_hekate
cleanup