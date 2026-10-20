#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

python3 "$repo_root/scripts/inspect-mini-plus-wifi-abi.py"
for init in \
    "$repo_root/rootfs/mini-plus-minimal/init" \
    "$repo_root/rootfs/mini-plus-frontend/init"; do
    grep -Fq 'rockchip_wlan/rkwifi/bcmdhd/bcmdhd.ko' "$init"
    grep -Fq 'firmware_path=/etc/firmware/fw_bcmdhd.bin' "$init"
    grep -Fq 'nvram_path=/etc/firmware/nvram.txt' "$init"
    grep -Fq 'S34_WIFI_MODULE_LOADED' "$init"
    ! grep -Fq 'insmod -f' "$init"
    ! grep -Fq '8821cs' "$init"
done
grep -Fq 'runtime-live' \
    "$repo_root/scripts/build-mini-plus-frontend-system.sh"
grep -Fq 'modules/bcmdhd.ko' \
    "$repo_root/scripts/build-mini-plus-frontend-system.sh"
grep -Fq 'firmware/wifi/fw_bcm43438a1.bin' \
    "$repo_root/scripts/build-mini-plus-frontend-system.sh"
grep -Fq 'firmware/wifi/nvram_ap6212a.txt' \
    "$repo_root/scripts/build-mini-plus-frontend-system.sh"
grep -Fq 'stock-bcmdhd-sdio-02d0-a9a6' \
    "$repo_root/scripts/build-mini-plus-app-layer.sh"
! grep -Fq 'allow-rtl8821cs-force-load' \
    "$repo_root/scripts/build-mini-plus-app-layer.sh"

echo 'miniplus_wifi_module_contract=result-ok driver=bcmdhd force_load=absent'
