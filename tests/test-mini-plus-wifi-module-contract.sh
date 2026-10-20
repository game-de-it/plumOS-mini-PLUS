#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

python3 "$repo_root/scripts/inspect-mini-plus-wifi-abi.py"
for init in \
    "$repo_root/rootfs/mini-plus-minimal/init" \
    "$repo_root/rootfs/mini-plus-frontend/init"; do
    grep -Fq 'allow-rtl8821cs-force-load' "$init"
    grep -Fq 'S34_WIFI_MODULE_LOADED_NORMAL' "$init"
    grep -Fq 'insmod -f "$module"' "$init"
    grep -Fq 'S34_WIFI_MODULE_LOADED_FORCED_ABI_COMPAT' "$init"
done
grep -Fq 'runtime/modules/8821cs.ko' \
    "$repo_root/scripts/build-mini-plus-frontend-system.sh"
grep -Fq 'wifi_risk=stock-module-vermagic-4.19.172-no-modversions' \
    "$repo_root/scripts/build-mini-plus-frontend-system.sh"
grep -Fq ' kmod ' "$repo_root/docker/mini-plus-tools/Dockerfile"
grep -Fq 'allow-rtl8821cs-force-load' \
    "$repo_root/scripts/build-mini-plus-app-layer.sh"
grep -Fq 'scope=full-host-candidate-only' \
    "$repo_root/scripts/build-mini-plus-app-layer.sh"

echo 'miniplus_wifi_module_contract=result-ok force_load=explicit-marker-only'
