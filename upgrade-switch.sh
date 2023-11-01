#!/usr/bin/env bash

set -e

if [ -z "$1" ]; then
    echo "Usage: ./upgrade-switch.sh /path-to-switch-sd/root"
    exit 1
fi

switch_mount_usb_path="$1"

cleanup() {
    rm -rf test

    rm -rf .tmp
    mkdir -p .tmp

    rm -rf .tmp/atmopshere
    mkdir -p .tmp/hekate
}

setup_fusee_launcher() {

    root_dir=$(pwd)

    mkdir -p .tools/fusee_launcher
    mkdir -p .tmp

    if [ ! -f ".tools/fusee_launcher/fusee-launcher.py" ]; then
        echo Fusee launcher is missing, downloading
        fusee_launcher_repository=Qyriad/fusee-launcher
        fusee_launcher_tarball_url=$(curl -Ls https://api.github.com/repos/${fusee_launcher_repository}/releases/latest | grep tarball_url | cut -d '"' -f 4)
        echo $fusee_launcher_tarball_url
        curl -o .tmp/fusee_launcher.tar.gz -L $fusee_launcher_tarball_url

        tar -xf .tmp/fusee_launcher.tar.gz -C .tools/fusee_launcher --strip-components 1

        pip install -r ./.tools/fusee_launcher/requirements.txt

        # ./.tools/fusee_launcher/fusee-launcher.py 
    else 
        echo Fusee launcher is available
    fi

    cd $root_dir

}

download_hekate() {
    echo Downloading latest hekate
    hekate_zip_url=$(curl -Ls https://api.github.com/repos/CTCaer/hekate/releases/latest | grep  hekate_ctcaer | grep browser_download_url  | cut -d '"' -f 4)
    curl -o .tmp/hekate.zip -L $hekate_zip_url
    unzip -o .tmp/hekate.zip -d .tools/hekate
    hekate_payload_bin_path=$(find .tools/hekate -type f -name 'hekate_*.bin')
}

inject_payload() {
    echo Injecting payload
    ./.tools/fusee_launcher/fusee-launcher.py $hekate_payload_bin_path || echo "Couldn't inject payload, skipping (is switch already in hekate mode?)"
}

wait_switch_mount() {
    echo "Waiting for switch mount at $switch_mount_usb_path...  please mount USB Mass Storage inside Hekate (USB Tools -> SD Card)"
    while [ ! -d "$switch_mount_usb_path" ]; do sleep 1; done
    echo Switch mounted
}

download_atmosphere() {
    echo Downloading latest atmosphere
    atmosphere_zip_url=$(curl -Ls https://api.github.com/repos/Atmosphere-NX/Atmosphere/releases/latest | grep browser_download_url | grep atmosphere | grep zip | cut -d '"' -f 4)
    echo Got atmosphere URL $atmosphere_zip_url
    curl -L --output .tmp/atmosphere.zip $atmosphere_zip_url
    unzip -o .tmp/atmosphere.zip -d .tools/atmosphere
}

download_emmmc_hosts() {
    echo Download emummc.txt
    mkdir -p .tools/atmosphere/atmosphere/hosts
    curl -L --output .tools/atmosphere/atmosphere/hosts/emummc.txt https://nh-server.github.io/switch-guide/files/emummc.txt
}

download_hbstore() {
    echo Downloading latest hbstore
    hbstore_nro_url=$(curl -Ls https://api.github.com/repos/fortheusers/hb-appstore/releases/latest | grep browser_download_url | grep nro | cut -d '"' -f 4)
    mkdir -p .tools/atmosphere/switch/appstore
    curl -L --output .tools/atmosphere/switch/appstore/appstore.nro $hbstore_nro_url
}

download_bootlogos() {
    echo Downloading bootlogos
    curl -L --output .tmp/bootlogos.zip https://nh-server.github.io/switch-guide/files/bootlogos.zip
    unzip -o .tmp/bootlogos.zip -d .tools/bootlogos
    cp -arf .tools/bootlogos/. .tools/atmosphere/
}

download_tegraRCM() {
    echo Downloading TegraRCM
    tegrarcm_bin_url=$(curl -Ls https://api.github.com/repos/suchmememanyskill/TegraExplorer/releases/latest | grep browser_download_url | grep bin | cut -d '"' -f 4)
    mkdir -p .tools/atmosphere/bootloader/payloads/
    curl -L --output .tools/atmosphere/bootloader/payloads/TegraExplorer.bin $tegrarcm_bin_url
}

downloadSysPatch() {
    echo Downloading SysPatch
    syspatch_zip_url=$(curl -Ls https://api.github.com/repos/ITotalJustice/sys-patch/releases/latest | grep browser_download_url | grep zip | cut -d '"' -f 4)
    curl -L --output .tmp/syspatch.zip $syspatch_zip_url
    unzip -o .tmp/syspatch.zip -d .tools/syspatch
    cp -arf .tools/syspatch/. .tools/atmosphere/
}

download_overlay() {
    echo Downloading nx-ovlloader
    nx_ovlloader_zip_url=$(curl -Ls https://api.github.com/repos/WerWolv/nx-ovlloader/releases/latest | grep browser_download_url | grep zip | cut -d '"' -f 4)
    curl -L --output .tmp/nx_ovlloader.zip $nx_ovlloader_zip_url
    unzip -o .tmp/nx_ovlloader.zip -d .tools/nx_ovlloader
    cp -arf .tools/nx_ovlloader/. .tools/atmosphere/

    echo Downloading Tesla-Menu
    tesla_menu_zip_url=$(curl -Ls https://api.github.com/repos/WerWolv/Tesla-Menu/releases/latest | grep browser_download_url | grep zip | cut -d '"' -f 4)
    curl -L --output .tmp/tesla_menu.zip $tesla_menu_zip_url
    unzip -o .tmp/tesla_menu.zip -d .tools/tesla_menu
    cp -arf .tools/tesla_menu/. .tools/atmosphere/
}

download_syscon() {
    echo Downloading sys-con
    sys_con_zip_url=$(curl -Ls https://api.github.com/repos/cathery/sys-con/releases/latest | grep browser_download_url | grep zip | cut -d '"' -f 4)
    curl -L --output .tmp/sys_con.zip $sys_con_zip_url
    unzip -o .tmp/sys_con.zip -d .tools/sys_con
    cp -arf .tools/sys_con/. .tools/atmosphere/
}

copy_atmosphere() {
    echo Copying atmosphere
    cp -arf .tools/atmosphere/. "$switch_mount_usb_path/"
}

copy_hekate() {
    echo Copying hekate
    cp -arf .tools/hekate/bootloader/. "$switch_mount_usb_path/bootloader"
}

create_safe_configs() {
    # don't patch sysmmc
    if [ ! -f ".tools/atmosphere/config/sys-patch/config.ini" ]; then
        mkdir -p .tools/atmosphere/config/sys-patch
        cp ./sys-patch-config.ini .tools/atmosphere/config/sys-patch/config.ini
    fi
}

cleanup
setup_fusee_launcher
download_hekate
inject_payload
wait_switch_mount
download_atmosphere
download_emmmc_hosts
download_bootlogos
download_tegraRCM
download_overlay
download_syscon
create_safe_configs
copy_atmosphere
copy_hekate
cleanup