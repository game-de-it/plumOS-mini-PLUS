#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
stock_mount=${1:-/Volumes/EMUELEC}
system=$stock_mount/SYSTEM
out=$repo_root/artifacts/vendor/mini-plus-stock-source/runtime
image=${PLUMOS_STOCK_EXTRACT_IMAGE:-plumos-mini-plus-tools:dev}
expected_system_sha=abe0bb60006a6c54f3995c1190cee47907d34636ed9f61fb020db30add333147
kernel_release=4.19.193-g5a07852a55cf-dirty

[ -f "$system" ] || {
    echo "missing stock SYSTEM: $system" >&2
    exit 2
}
mount | grep -F "on $stock_mount " | grep -q 'read-only' || {
    echo "refusing to read a writable stock volume: $stock_mount" >&2
    exit 2
}
actual_system_sha=$(shasum -a 256 "$system" | awk '{print $1}')
[ "$actual_system_sha" = "$expected_system_sha" ] || {
    echo "unexpected stock SYSTEM sha256: $actual_system_sha" >&2
    exit 2
}
docker image inspect "$image" >/dev/null 2>&1 ||
    "$repo_root/scripts/build-mini-plus-tools-image.sh"

case "$out" in
    "$repo_root"/artifacts/vendor/mini-plus-stock-source/runtime) ;;
    *) echo "unsafe output path: $out" >&2; exit 2 ;;
esac
mkdir -p "$out"
find "$out" -depth -delete
mkdir -p "$out/modules" "$out/firmware/rtl_bt" "$out/gpu"

docker run --rm --platform linux/arm64 \
    -e KERNEL_RELEASE="$kernel_release" \
    -v "$stock_mount:/stock:ro" \
    -v "$out:/out" \
    "$image" sh -eu -c '
        extract() {
            source_path=$1
            destination=$2
            unsquashfs -cat /stock/SYSTEM "$source_path" > "/out/$destination"
        }
        base="usr/lib/kernel-overlays/base"
        modules="$base/lib/modules/$KERNEL_RELEASE"
        extract "$modules/kernel/drivers/net/wireless/rockchip_wlan/rtl8821cs/8821cs.ko" modules/8821cs.ko
        extract "$modules/kernel/drivers/usb/dwc3/dwc3.ko" modules/dwc3.ko
        extract "$modules/kernel/drivers/usb/dwc3/dwc3-of-simple.ko" modules/dwc3-of-simple.ko
        extract "$modules/kernel/drivers/usb/gadget/udc/udc-core.ko" modules/udc-core.ko
        extract "$base/lib/firmware/rtl_bt/rtl8821cs_config.bin" firmware/rtl_bt/rtl8821cs_config.bin
        extract "$base/lib/firmware/rtl_bt/rtl8821cs_fw.bin" firmware/rtl_bt/rtl8821cs_fw.bin
        extract usr/lib/libmali.so.1.9.0 gpu/libmali-aarch64.so.1.9.0
        extract usr/lib32/libmali.so.1.9.0 gpu/libmali-armhf.so.1.9.0
    '

manifest=$out/manifest.tsv
{
    printf 'format\tplumos-mini-plus-stock-runtime-v1\n'
    printf 'device\tgkd-mini-plus\n'
    printf 'source\tSYSTEM\n'
    printf 'source_sha256\t%s\n' "$actual_system_sha"
    printf 'kernel_release\t%s\n' "$kernel_release"
    find "$out" -type f ! -name manifest.tsv -print0 | LC_ALL=C sort -z | \
        while IFS= read -r -d '' file; do
            relative=${file#"$out"/}
            size=$(stat -f '%z' "$file")
            sha=$(shasum -a 256 "$file" | awk '{print $1}')
            printf 'file\t%s\t%s\t%s\n' "$relative" "$size" "$sha"
        done
} > "$manifest"

echo "created: $out"
echo "manifest: $manifest"
