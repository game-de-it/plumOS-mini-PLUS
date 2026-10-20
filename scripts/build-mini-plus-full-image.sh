#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tools_image=${PLUMOS_MINI_PLUS_TOOLS_IMAGE:-plumos-mini-plus-tools:dev}

if [ "${1:-}" != "--inside" ]; then
    mode=${1:-}
    case "$mode" in
        '') app_mode= ;;
        --assemble-only) app_mode=--assemble-only ;;
        *) echo "usage: $0 [--assemble-only]" >&2; exit 2 ;;
    esac
    "$repo_root/scripts/build-mini-plus-tools-image.sh"
    "$repo_root/scripts/build-mini-plus-image.sh"
    "$repo_root/scripts/build-mini-plus-frontend.sh"
    "$repo_root/scripts/build-mini-plus-frontend-system.sh"
    if [ -n "$app_mode" ]; then
        PLUMOS_MINI_PLUS_INCLUDE_CAPTURED_VENDOR_GPU=1 \
            "$repo_root/scripts/build-mini-plus-app-layer.sh" "$app_mode"
    else
        PLUMOS_MINI_PLUS_INCLUDE_CAPTURED_VENDOR_GPU=1 \
            "$repo_root/scripts/build-mini-plus-app-layer.sh"
    fi
    exec docker run --rm --platform linux/arm64 \
        -e SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-}" \
        -e PLUMOS_MINI_PLUS_VERSION="${PLUMOS_MINI_PLUS_VERSION:-0.1.0-dev}" \
        -v "$repo_root:/work" -w /work "$tools_image" \
        ./scripts/build-mini-plus-full-image.sh --inside
fi

repo_root=/work
prefix=$repo_root/artifacts/vendor/mini-plus-stock-source/rockchip-boot-prefix.bin
app=$repo_root/output/app-layer/mini-plus/plumos
system_dir=$repo_root/output/system-rootfs/mini-plus-frontend/payload
initramfs=$repo_root/output/initramfs/mini-plus-boot/payload/initramfs-plumos-mini-plus.cpio.gz
out_dir=$repo_root/output/image/mini-plus-full
work=$repo_root/work/mini-plus-full-image
version=${PLUMOS_MINI_PLUS_VERSION:-0.1.0-dev}
source_ref=$(git -c safe.directory="$repo_root" -C "$repo_root" rev-parse --short HEAD 2>/dev/null || printf unknown)
source_epoch=${SOURCE_DATE_EPOCH:-}
[ -n "$source_epoch" ] || source_epoch=$(git -c safe.directory="$repo_root" -C "$repo_root" show -s --format=%ct HEAD)
case "$source_epoch" in ''|*[!0-9]*) echo 'invalid SOURCE_DATE_EPOCH' >&2; exit 2;; esac

expected_prefix=aa8bd95d5d75aaab1977c5e58732d67545221649a08e6b7afda36aee208e26e9
test "$(stat -c '%s' "$prefix")" -eq 16777216
test "$(sha256sum "$prefix" | cut -d' ' -f1)" = "$expected_prefix"
(cd "$system_dir" && sha256sum -c checksums.sha256)
(cd "${initramfs%/*}" && sha256sum -c checksums.sha256)
(cd "$app" && sha256sum --quiet -c checksums.sha256)
test -f "$app/config/system/allow-rtl8821cs-force-load"
test -f "$app/components/libretro-cores/manifest.json"

case "$work" in /work/work/mini-plus-full-image) ;; *) exit 2;; esac
find "$work" -depth -delete 2>/dev/null || true
mkdir -p "$work/boot" "$work/storage" "$out_dir"
cp -a "$repo_root/work/mini-plus-image/boot/." "$work/boot/"
cp -a "$app" "$work/storage/plumos"

install -m 0644 "$system_dir/SYSTEM" "$work/boot/SYSTEM"
install -m 0644 "$system_dir/SYSTEM.manifest" "$work/boot/SYSTEM.manifest"
system_sha=$(sha256sum "$system_dir/SYSTEM" | cut -d' ' -f1)
printf '%s  SYSTEM\n' "$system_sha" > "$work/boot/SYSTEM.sha256"
kernel_sha=$(sha256sum "$work/boot/Image" | cut -d' ' -f1)
dtb=$work/boot/dtbs/4.19.193-51-rockchip-gb2c01b3d79f2/rockchip/rk3566-gkdmini-pro.dtb
dtb_sha=$(sha256sum "$dtb" | cut -d' ' -f1)
initramfs_sha=$(sha256sum "$initramfs" | cut -d' ' -f1)
cat > "$work/boot/plumos-image.manifest" <<EOF
format=plumos-mini-plus-full-host-candidate-v1
device=gkd-mini-plus
architecture=aarch64
version=$version
source_ref=$source_ref
source_date_epoch=$source_epoch
boot_prefix_sha256=$expected_prefix
stock_kernel_sha256=$kernel_sha
stock_dtb_sha256=$dtb_sha
initramfs_sha256=$initramfs_sha
system_sha256=$system_sha
layout=raw-prefix-16MiB,p1-fat32-512MiB,p2-ext4-4096MiB
app_layer=full
catalog_complete=true
emulator_runtime=host-verified-device-acceptance-pending
wifi=experimental-stock-rtl8821cs-normal-then-explicit-force-load
wifi_force_gate=/storage/plumos/config/system/allow-rtl8821cs-force-load
ssh=dropbear-port-22-root-user
physical_boot_status=frontend-and-basic-controller-user-reported
release_complete=false
publishable=no
EOF

mkdir -p "$work/storage/plumos/logs" "$work/storage/plumos/state" \
    "$work/storage/plumos/saves" "$work/storage/plumos/states" \
    "$work/storage/plumos/config/frontend" "$work/storage/plumos/config/system" \
    "$work/storage/plumos/config/retroarch" "$work/storage/update-state"
(cd "$work/storage/plumos" && sha256sum --quiet -c checksums.sha256)

boot_start=32768
boot_sectors=1048576
storage_start=$((boot_start + boot_sectors))
storage_sectors=8388608
total_sectors=$((storage_start + storage_sectors))
image_path=$out_dir/plumOS-mini-PLUS-$version-full-host-candidate.img
boot_fat=$work/boot.fat
storage_ext4=$work/storage.ext4
truncate -s "$((total_sectors * 512))" "$image_path"
dd if="$prefix" of="$image_path" bs=1M count=16 conv=notrunc status=none
parted -s "$image_path" unit s mklabel msdos \
    mkpart primary fat32 "${boot_start}s" "$((storage_start - 1))s" \
    mkpart primary ext4 "${storage_start}s" "$((total_sectors - 1))s" \
    set 1 boot on 2> "$work/parted.stderr"
grep -v 'udevadm: not found' "$work/parted.stderr" >&2 || true
printf '\102\125\102\114' | dd of="$image_path" bs=1 seek=440 conv=notrunc status=none

root_uuid=42554242-4c45-5359-5300-000000000002
truncate -s "$((boot_sectors * 512))" "$boot_fat"
truncate -s "$((storage_sectors * 512))" "$storage_ext4"
find "$work/boot" "$work/storage" -exec touch -h -d "@$source_epoch" {} +
SOURCE_DATE_EPOCH="$source_epoch" mkfs.vfat --invariant -F 32 -n PLUMBOOT \
    -i 42554242 "$boot_fat" >/dev/null
MTOOLS_SKIP_CHECK=1 mcopy -m -o -s -i "$boot_fat" "$work/boot/"* ::/
E2FSPROGS_FAKE_TIME="$source_epoch" mkfs.ext4 -q -F -L PLUMOS_DATA \
    -U "$root_uuid" \
    -E lazy_itable_init=0,lazy_journal_init=0,hash_seed="$root_uuid" \
    -d "$work/storage" "$storage_ext4"

dd if="$boot_fat" of="$image_path" bs=512 seek="$boot_start" conv=notrunc,sparse status=none
dd if="$storage_ext4" of="$image_path" bs=512 seek="$storage_start" conv=notrunc,sparse status=none
cmp -i 512:512 -n 16776704 "$prefix" "$image_path"
fsck.fat -vn "$boot_fat" >/dev/null
e2fsck -fn "$storage_ext4" >/dev/null

image_size=$(stat -c '%s' "$image_path")
image_sha=$(sha256sum "$image_path" | cut -d' ' -f1)
cat > "$out_dir/image.manifest" <<EOF
format=plumos-mini-plus-full-host-candidate-v1
file=$(basename "$image_path")
image_size=$image_size
image_sha256=$image_sha
source_ref=$source_ref
source_date_epoch=$source_epoch
boot_prefix_sha256=$expected_prefix
p1_filesystem_sha256=$(sha256sum "$boot_fat" | cut -d' ' -f1)
p2_filesystem_sha256=$(sha256sum "$storage_ext4" | cut -d' ' -f1)
app_layer=full
catalog_complete=true
wifi=experimental-stock-rtl8821cs-normal-then-explicit-force-load
physical_boot_status=frontend-and-basic-controller-user-reported
release_complete=false
publishable=no
EOF
(cd "$out_dir" && sha256sum "$(basename "$image_path")" image.manifest > checksums.sha256)
echo "miniplus_full_image=result-ok image=$image_path sha256=$image_sha"
