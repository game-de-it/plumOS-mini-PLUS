#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/plumos-mini-plus-sdr104-test.XXXXXX")
cleanup() {
    case "$test_dir" in
        "${TMPDIR:-/tmp}"/plumos-mini-plus-sdr104-test.*)
            find "$test_dir" -depth -delete
            ;;
    esac
}
trap cleanup EXIT HUP INT TERM

command -v dtc >/dev/null 2>&1
command -v fdtoverlay >/dev/null 2>&1

source_dts=$repo_root/configs/device-tree/mini-plus-sd1-sdr104-overlay.dts
baseline=$repo_root/artifacts/vendor/mini-plus-stock-source/runtime-live/runtime.dtb
dtc -@ -I dts -O dtb -o "$test_dir/overlay.dtbo" "$source_dts"
fdtoverlay -i "$baseline" -o "$test_dir/merged.dtb" "$test_dir/overlay.dtbo"

test "$(fdtget -t s "$test_dir/overlay.dtbo" /fragment@0 target-path)" = \
    /dwmmc@fe2b0000
fdtget -p "$test_dir/overlay.dtbo" /fragment@0/__overlay__ | \
    grep -qx sd-uhs-sdr104
fdtget -p "$test_dir/merged.dtb" /dwmmc@fe2b0000 | \
    grep -qx sd-uhs-sdr104

python3 "$repo_root/scripts/compare-fdt.py" "$baseline" "$test_dir/merged.dtb" \
    > "$test_dir/diff.txt"
test "$(wc -l < "$test_dir/diff.txt" | tr -d ' ')" -eq 2
grep -qx 'ADDED /dwmmc@fe2b0000:sd-uhs-sdr104 = <empty>' "$test_dir/diff.txt"
grep -qx 'summary base_properties=4231 runtime_properties=4232 changed=1' \
    "$test_dir/diff.txt"

/bin/sh -n "$repo_root/scripts/prepare-mini-plus-sd1-sdr104-test-macos.sh"

card=$test_dir/PLUMBOOT
mkdir -p "$card/dtbs/4.19.193-51-rockchip-gb2c01b3d79f2/rockchip"
cp "$repo_root/artifacts/vendor/mini-plus-stock-source/boot/uEnv.txt" "$card/uEnv.txt"
cp "$repo_root/artifacts/vendor/mini-plus-stock-source/boot/dtbs/4.19.193-51-rockchip-gb2c01b3d79f2/rockchip/rk3566-gkdmini-pro.dtb" \
    "$card/dtbs/4.19.193-51-rockchip-gb2c01b3d79f2/rockchip/"
PLUMOS_MINI_PLUS_SDR104_BACKUP_ROOT=$test_dir/host-backup \
    "$repo_root/scripts/prepare-mini-plus-sd1-sdr104-test-macos.sh" --apply "$card" \
    > "$test_dir/apply.txt"
grep -qx 'user_overlays=mini-plus-sd1-sdr104' "$card/uEnv.txt"
test -f "$card/overlay-user/mini-plus-sd1-sdr104.dtbo"
PLUMOS_MINI_PLUS_SDR104_BACKUP_ROOT=$test_dir/host-backup \
    "$repo_root/scripts/prepare-mini-plus-sd1-sdr104-test-macos.sh" --rollback "$card" \
    > "$test_dir/rollback.txt"
cmp "$repo_root/artifacts/vendor/mini-plus-stock-source/boot/uEnv.txt" "$card/uEnv.txt"
test ! -e "$card/overlay-user/mini-plus-sd1-sdr104.dtbo"
grep -q '^sd1_sdr104_test=rolled-back$' "$test_dir/rollback.txt"
echo 'mini PLUS SD1 SDR104 overlay tests passed'
